######################################
# Makefile by Disco2Makefile.py
######################################

######################################
# target
######################################
TARGET = $TARGET

######################################
#JTAG and environment configuration
######################################
OPENOCD           ?= openocd
OPENOCD_INTERFACE ?= interface/stlink-v2-1.cfg
OPENOCD_CMDS      ?=
OPENOCD_TARGET    ?= target/stm32f7x.cfg


######################################
# building variables
######################################
# debug build?
DEBUG = 1
# optimization
OPT = -O0

#######################################
# pathes
#######################################
# Build path
BUILD_DIR = build

######################################
# source
######################################
$C_SOURCES  
$ASM_SOURCES

#######################################
# binaries
#######################################
CC = arm-none-eabi-gcc
AS = arm-none-eabi-gcc -x assembler-with-cpp
CP = arm-none-eabi-objcopy
AR = arm-none-eabi-ar
SZ = arm-none-eabi-size
HEX = $$(CP) -O ihex
BIN = $$(CP) -O binary -S
 
#######################################
# CFLAGS
#######################################
# macros for gcc
$AS_DEFS
$C_DEFS
# includes for gcc
$AS_INCLUDES
$C_INCLUDES
# compile gcc flags
ASFLAGS = $MCU $$(AS_DEFS) $$(AS_INCLUDES) $$(OPT) -Wall -fdata-sections -ffunction-sections
CFLAGS = $MCU $$(C_DEFS) $$(C_INCLUDES) $$(OPT) -Wall -fdata-sections -ffunction-sections
ifeq ($$(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif
# Generate dependency information
CFLAGS += -std=c99 -MD -MP -MF .dep/$$(@F).d

#######################################
# LDFLAGS
#######################################
# link script
$LDSCRIPT
# libraries
LIBS = -lc -lm -lnosys
LIBDIR =
LDFLAGS = $LDMCU -specs=nano.specs -T$$(LDSCRIPT) $$(LIBDIR) $$(LIBS) -Wl,-Map=$$(BUILD_DIR)/$$(TARGET).map,--cref -Wl,--gc-sections

# default action: build all
all: $$(BUILD_DIR)/$$(TARGET).elf $$(BUILD_DIR)/$$(TARGET).hex $$(BUILD_DIR)/$$(TARGET).bin

#######################################
# build the application
#######################################
# list of objects
OBJECTS = $$(addprefix $$(BUILD_DIR)/,$$(notdir $$(C_SOURCES:.c=.o)))
vpath %.c $$(sort $$(dir $$(C_SOURCES)))
# list of ASM program objects
OBJECTS += $$(addprefix $$(BUILD_DIR)/,$$(notdir $$(ASM_SOURCES:.s=.o)))
vpath %.s $$(sort $$(dir $$(ASM_SOURCES)))

$$(BUILD_DIR)/%.o: %.c Makefile | $$(BUILD_DIR) 
	$$(CC) -c $$(CFLAGS) -Wa,-a,-ad,-alms=$$(BUILD_DIR)/$$(notdir $$(<:.c=.lst)) $$< -o $$@

$$(BUILD_DIR)/%.o: %.s Makefile | $$(BUILD_DIR)
	$$(AS) -c $$(CFLAGS) $$< -o $$@

$$(BUILD_DIR)/$$(TARGET).elf: $$(OBJECTS) Makefile
	$$(CC) $$(OBJECTS) $$(LDFLAGS) -o $$@
	$$(SZ) $$@

$$(BUILD_DIR)/%.hex: $$(BUILD_DIR)/%.elf | $$(BUILD_DIR)
	$$(HEX) $$< $$@
	
$$(BUILD_DIR)/%.bin: $$(BUILD_DIR)/%.elf | $$(BUILD_DIR)
	$$(BIN) $$< $$@	
	
$$(BUILD_DIR):
	mkdir -p $$@		

#######################################
# Flash the stm.
flash:
	$$(OPENOCD) -d2 -f $$(OPENOCD_INTERFACE) $$(OPENOCD_CMDS) -f $$(OPENOCD_TARGET) -c init -c targets -c "reset halt" \
                 -c "flash write_image erase $$(BUILD_DIR)/$$(TARGET).elf" -c "verify_image $$(BUILD_DIR)/$$(TARGET).elf" -c "reset run" -c shutdown

halt:
	$$(OPENOCD) -d0 -f $$(OPENOCD_INTERFACE) $$(OPENOCD_CMDS) -f $$(OPENOCD_TARGET) -c init -c targets -c "halt" -c shutdown

reset:
	$$(OPENOCD) -d0 -f $$(OPENOCD_INTERFACE) $$(OPENOCD_CMDS) -f $$(OPENOCD_TARGET) -c init -c targets -c "reset" -c shutdown

openocd:
	$$(OPENOCD) -d2 -f $$(OPENOCD_INTERFACE) $$(OPENOCD_CMDS) -f $$(OPENOCD_TARGET) -c init -c targets -c "\$$_TARGETNAME configure -rtos auto"


gdb: $$(BUILD_DIR)/$$(TARGET).elf
	$$(GDB) -ex "target remote localhost:3333" -ex "monitor reset halt"

erase:
	$$(OPENOCD) -d2 -f $$(OPENOCD_INTERFACE) -f $$(OPENOCD_TARGET) -c init -c targets -c "halt" -c "stm32f1x mass_erase 0" -c shutdown
#######################################
# clean up
#######################################
clean:
	-rm -fR .dep $$(BUILD_DIR)
  
#######################################
# dependencies
#######################################
-include $$(shell mkdir .dep 2>/dev/null) $$(wildcard .dep/*)

.PHONY: clean all

# *** EOF ***
