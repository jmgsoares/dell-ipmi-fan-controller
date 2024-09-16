#!/bin/bash

IPMIHOST=192.168.1.1
IPMIUSER=root
IPMIPW=calvin
IPMIEK=0000000000000000000000000000000000000000

# Set up IPMI fan control command
ipmifanctl=(ipmitool -I lanplus -H "$IPMIHOST" -U "$IPMIUSER" -P "$IPMIPW" -y "$IPMIEK" raw 0x30 0x30)

# Temperature sensor IDs and thresholds
CPUID0=0Eh
CPUID1=0Fh
AMBIENT_ID=04h
EXHAUST_ID=01h
EXHTEMP_MAX=65

# Array of temperature thresholds and corresponding fan speeds in decimal
# Format: (temperature_threshold_1 speed_decimal_1 temperature_threshold_2 speed_decimal_2 ...)
FAN_SPEEDS=(75 100 73 90 70 80 67 50 65 40 63 30 55 28 50 25 45 23 40 20)

# Function to set fan speed, converting decimal speed to hexadecimal
set_fan_speed() {
    local speed_decimal="$1"
    local speed_hex

    echo "$speed_decimal"

    # Convert decimal speed to hexadecimal
    speed_hex=$(printf '0x%x' "$speed_decimal")

    #echo "Setting fan speed to $speed_hex (from $speed_decimal%)"
    "${ipmifanctl[@]}" 0x01 0x00  > /dev/null 2>&1 # Manual mode
    "${ipmifanctl[@]}" 0x02 0xff "$speed_hex" > /dev/null 2>&1  # Set fan speed
}

# Function to adjust fan speed based on CPU temperature using a threshold list
adjust_fan_speed() {
    local highest_temp="$1"
    local cpu_label="$2"

    for ((i = 0; i < ${#FAN_SPEEDS[@]}; i+=2)); do
        threshold="${FAN_SPEEDS[i]}"
        speed="${FAN_SPEEDS[i+1]}"

        if [ "$highest_temp" -ge "$threshold" ]; then
            #echo "Hottest CPU: $cpu_label: $highest_temp C >= $threshold C. Setting fan speed to $speed%"
            # echo "$cpu_label,$highest_temp,$speed"
            set_fan_speed "$speed"
            return
        fi
    done

    # If no thresholds matched, set the default fan speed to 25%
    set_fan_speed 25  # 25% speed
}

# Main loop
while : ; do
    # Fetch sensor data once
    IPMIPULLDATA=$(ipmitool -I lanplus -H "$IPMIHOST" -U "$IPMIUSER" -P "$IPMIPW" -y "$IPMIEK" sdr type temperature)

    if [ ! -z "$IPMIPULLDATA" ]; then
        # Extract temperatures
        AMBIENTTEMP=$(echo "$IPMIPULLDATA" | grep "$AMBIENT_ID" | awk '{print $10}')
        EXHAUSTTEMP=$(echo "$IPMIPULLDATA" | grep "$EXHAUST_ID" | awk '{print $10}')
        CPUTEMP0=$(echo "$IPMIPULLDATA" | grep "$CPUID0" | awk '{print $9}')
        CPUTEMP1=$(echo "$IPMIPULLDATA" | grep "$CPUID1" | awk '{print $9}')

	echo -n "$AMBIENTTEMP,$EXHAUSTTEMP,$CPUTEMP0,$CPUTEMP1,"

        # Check exhaust temperature
        if [ "$EXHAUSTTEMP" -ge $EXHTEMP_MAX ]; then
            echo "Exhaust temp is high!! : $EXHAUSTTEMP C!"
            echo "Setting auto fan mode on"
            "${ipmifanctl[@]}" 0x01 0x01  # Auto mode
            break
        fi

        # Determine which CPU has the highest temperature
        if [ "$CPUTEMP0" -ge "$CPUTEMP1" ]; then
            highest_temp="$CPUTEMP0"
            cpu_label="CPU0"
        else
            highest_temp="$CPUTEMP1"
            cpu_label="CPU1"
        fi

        # Adjust fan speed based on the highest temperature
        adjust_fan_speed "$highest_temp" "$cpu_label"

        sleep 1
    else
        echo "No data pulled! Possible issue"
        echo "$IPMIPULLDATA"
        echo "Setting auto fan mode on"
        "${ipmifanctl[@]}" 0x01 0x01  # Auto mode
    fi
done
