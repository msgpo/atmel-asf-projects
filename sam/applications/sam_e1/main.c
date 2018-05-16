/**
 * \file
 *
 * \brief Low Power Application.
 *
 * Copyright (c) 2012-2016 Atmel Corporation. All rights reserved.
 *
 * \asf_license_start
 *
 * \page License
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. The name of Atmel may not be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * 4. This software may only be redistributed and used in connection with an
 *    Atmel microcontroller product.
 *
 * THIS SOFTWARE IS PROVIDED BY ATMEL "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT ARE
 * EXPRESSLY AND SPECIFICALLY DISCLAIMED. IN NO EVENT SHALL ATMEL BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * \asf_license_stop
 *
 */

/**
 * \mainpage Low Power Application
 *
 * \section Purpose
 *
 * This example shows all the different low power modes with several types
 * of wake-up sources. And the consumption of the core in different power
 * modes can be measured.
 *
 * \section Requirements
 *
 * This package can be used with SAM evaluation kits.
 *
 * \section Description
 *
 * The program will display a menu on console. It allows users to change the
 * configuration and enter into a different power mode, and then measure the
 * power consumption.
 *
 * For Eks, an amperemeter has to be plugged on the board instead of the
 * VDDx jumper.
 *
 * Note that for better consumption measurement:
 * - Run program out of flash without ICE connected.
 *
 * \section Usage
 *
 * -# Build the program and download it into the evaluation board.
 * -# On the computer, open and configure a terminal application
 *    (e.g., HyperTerminal on Microsoft Windows) with these settings:
 *   - 115200 bauds
 *   - 8 bits of data
 *   - No parity
 *   - 1 stop bit
 *   - No flow control
 * -# Start the application.
 */
/*
 * Support and FAQ: visit <a href="http://www.atmel.com/design-support/">Atmel Support</a>
 */

#include <asf.h>
#include "stdio_serial.h"
#include "conf_board.h"
#include "conf_clock.h"
#include "conf_uart_serial.h"
#include "conf_usb.h"
#include "low_power_board.h"
#include "e1_ssc_tc.h"
#include "idt82v2081_asf.h"

#if !defined(PMC_PCK_PRES_CLK_1)
#define PMC_PCK_PRES_CLK_1   PMC_PCK_PRES(0)
#define PMC_PCK_PRES_CLK_2   PMC_PCK_PRES(1)
#define PMC_PCK_PRES_CLK_4   PMC_PCK_PRES(2)
#define PMC_PCK_PRES_CLK_8   PMC_PCK_PRES(3)
#define PMC_PCK_PRES_CLK_16  PMC_PCK_PRES(4)
#define PMC_PCK_PRES_CLK_32  PMC_PCK_PRES(5)
#define PMC_PCK_PRES_CLK_64  PMC_PCK_PRES(6)
#endif

#define STRING_EOL    "\r"
#define STRING_HEADER "-- Osmocom E1 Example --\r\n" \
	"-- "BOARD_NAME " --\r\n" \
	"-- Compiled: "__DATE__ " "__TIME__ " --"STRING_EOL

#ifndef PLL_DEFAULT_MUL
#define PLL_DEFAULT_MUL  7
#endif

#ifndef PLL_DEFAULT_DIV
#define PLL_DEFAULT_DIV  1
#endif

#ifndef MCK_DEFAULT_DIV
#define MCK_DEFAULT_DIV  PMC_MCKR_PRES_CLK_4
#endif

#ifndef example_switch_clock
#define example_switch_clock(a, b, c, d) \
	do {                                 \
		pmc_enable_pllack(a, b, c);      \
		pmc_switch_mck_to_pllack(d);     \
	} while (0)
#endif

#ifndef example_disable_pll
#define example_disable_pll()  pmc_disable_pllack()
#endif

#ifndef example_set_wakeup_from_wait_mode
#define example_set_wakeup_from_wait_mode() \
	pmc_set_fast_startup_input(WAKEUP_WAIT_INPUT_ID)
#endif

#ifndef example_set_wakeup_from_backup_mode
#define example_set_wakeup_from_backup_mode() \
	supc_set_wakeup_inputs(SUPC, WAKEUP_BACKUP_INPUT_ID, \
			WAKEUP_BACKUP_INPUT_ID)
#endif

/** Current MCK in Hz */
uint32_t g_ul_current_mck;

/** Button pressed flag */
volatile uint32_t g_ul_button_pressed = 0;

static struct idt82 g_idt;

/**
 * \brief Set default clock (MCK = 24MHz).
 */
static void set_default_working_clock(void)
{
#if (SAMG)
	/* Switch MCK to slow clock  */
	pmc_switch_mck_to_sclk(PMC_MCKR_PRES_CLK_1);

	/*
	 * Configure PLL and switch clock.
	 * MCK = XTAL * (PLL_DEFAULT_MUL+1) / PLL_DEFAULT_DIV / MCK_DEFAULT_DIV
	 *     = 24 MHz
	 */
	example_switch_clock(PLL_DEFAULT_MUL, PLL_COUNT, PLL_DEFAULT_DIV,
			MCK_DEFAULT_DIV);
#else
	/* Switch MCK to slow clock  */
	pmc_switch_mck_to_sclk(PMC_MCKR_PRES_CLK_1);

	/* Switch mainck to external xtal */
	pmc_switch_mainck_to_xtal(0, BOARD_OSC_STARTUP_US);

	/*
	 * Configure PLL and switch clock.
	 * MCK = XTAL * (PLL_DEFAULT_MUL+1) / PLL_DEFAULT_DIV / MCK_DEFAULT_DIV
	 *     = 24 MHz
	 */
	example_switch_clock(PLL_DEFAULT_MUL, PLL_COUNT, PLL_DEFAULT_DIV,
			MCK_DEFAULT_DIV);

	/* Disable unused clock to save power */
	pmc_osc_disable_fastrc();
#endif

	/* Save current clock */
#if SAMG55
	g_ul_current_mck = 48000000; /* 48MHz */
#else
	g_ul_current_mck = 24000000; /* 24MHz */
#endif
}

/**
 *  Configure UART console.
 */
static void configure_console(void)
{
	const usart_serial_options_t uart_serial_options = {
		.baudrate = CONF_UART_BAUDRATE,
#ifdef CONF_UART_CHAR_LENGTH
		.charlength = CONF_UART_CHAR_LENGTH,
#endif
		.paritytype = CONF_UART_PARITY,
#ifdef CONF_UART_STOP_BITS
		.stopbits = CONF_UART_STOP_BITS,
#endif
	};

	/* Configure console UART. */
	sysclk_enable_peripheral_clock(CONSOLE_UART_ID);
	pio_configure_pin_group(CONF_UART_PIO, CONF_PINS_UART,
			CONF_PINS_UART_FLAGS);
	stdio_serial_init(CONF_UART, &uart_serial_options);
}

/**
 *  Reconfigure UART console for changed MCK and baudrate.
 */
#if SAMG55
static void reconfigure_console(uint32_t ul_mck, uint32_t ul_baudrate)
{
	sam_usart_opt_t uart_serial_options;
	
	uart_serial_options.baudrate = ul_baudrate,
	uart_serial_options.char_length = CONF_UART_CHAR_LENGTH,
	uart_serial_options.parity_type = US_MR_PAR_NO;
	uart_serial_options.stop_bits = CONF_UART_STOP_BITS,
	uart_serial_options.channel_mode= US_MR_CHMODE_NORMAL,
	uart_serial_options.irda_filter = 0,

	/* Configure PMC */
	flexcom_enable(CONF_FLEXCOM);
	flexcom_set_opmode(CONF_FLEXCOM, FLEXCOM_USART);

	/* Configure PIO */
	pio_configure_pin_group(CONF_UART_PIO, CONF_PINS_UART,
			CONF_PINS_UART_FLAGS);

	/* Configure UART */
	usart_init_rs232(CONF_UART, &uart_serial_options, ul_mck);
	/* Enable the receiver and transmitter. */
	usart_enable_tx(CONF_UART);
	usart_enable_rx(CONF_UART);
}
#else
static void reconfigure_console(uint32_t ul_mck, uint32_t ul_baudrate)
{
	const sam_uart_opt_t uart_console_settings =
			{ ul_mck, ul_baudrate, UART_MR_PAR_NO };

	/* Configure PMC */
	pmc_enable_periph_clk(CONSOLE_UART_ID);

	/* Configure PIO */
	pio_configure_pin_group(CONF_UART_PIO, CONF_PINS_UART,
			CONF_PINS_UART_FLAGS);

	/* Configure UART */
	uart_init(CONF_UART, &uart_console_settings);
}
#endif

/**
 * \brief Initialize the chip for low power test.
 */
static void init_chip(void)
{
#if SAMG55
	/* Wait for the transmission done before changing clock */
	while (!usart_is_tx_empty(CONSOLE_UART)) {
	}
#else
	/* Wait for the transmission done before changing clock */
	while (!uart_is_tx_empty(CONSOLE_UART)) {
	}
#endif

	/* Disable all the peripheral clocks */
	pmc_disable_all_periph_clk();

	/* Disable brownout detector */
	supc_disable_brownout_detector(SUPC);

	/* Initialize the specific board */
	//init_specific_board();
}

/**
 * \brief Handler for button interrupt.
 *
 * \note This interrupt is for waking up from sleep mode or exiting from active
 * mode.
 */
static void button_handler(uint32_t ul_id, uint32_t ul_mask)
{
	if (PIN_PUSHBUTTON_WAKEUP_ID == ul_id &&
			PIN_PUSHBUTTON_WAKEUP_MASK == ul_mask) {
		g_ul_button_pressed = 1;
	}
}

/**
 *  \brief Configure the push button.
 *
 *  Configure the PIO as inputs and generate corresponding interrupt when
 *  pressed or released.
 */
static void configure_button(void)
{
	/* Adjust PIO debounce filter parameters, using 10 Hz filter. */
	pio_set_debounce_filter(PIN_PUSHBUTTON_WAKEUP_PIO,
			PIN_PUSHBUTTON_WAKEUP_MASK, 10);

	/* Initialize PIO interrupt handlers, see PIO definition in board.h. */
	pio_handler_set(PIN_PUSHBUTTON_WAKEUP_PIO, PIN_PUSHBUTTON_WAKEUP_ID,
			PIN_PUSHBUTTON_WAKEUP_MASK, PIN_PUSHBUTTON_WAKEUP_ATTR,
			button_handler);

	/* Enable PIO controller IRQs. */
	NVIC_EnableIRQ((IRQn_Type)PIN_PUSHBUTTON_WAKEUP_ID);

	/* Enable PIO line interrupts. */
	pio_enable_interrupt(PIN_PUSHBUTTON_WAKEUP_PIO,
			PIN_PUSHBUTTON_WAKEUP_MASK);
}

/**
 * \brief Display test core menu.
 */
static void display_menu_core(void)
{
	printf("\n\r");
	printf("===============================================\n\r");
	printf("Menu: press a key to continue.\n\r");
	printf("===============================================\n\r");
	printf("Configure:\n\r");
	printf("  F : 128-bit flash access\n\r");
	printf("  G : 64-bit flash access\n\r");
	printf("Mode:\n\r");
	printf("  A : Active Mode\n\r");
	printf("  S : Sleep Mode\n\r");
	printf("  W : Wait Mode\n\r");
#if (!(SAMG51 || SAMG53 || SAMG54))
	printf("  B : Backup Mode(Entered %d times).\n\r", (int)gpbr_read(GPBR0));
#endif
	printf("Quit:\n\r");
	printf("  Q : Quit test.\n\r");

	printf("\n\r");
	printf("-----------------------------------------------\n\r");
	printf("Current configuration:\n\r");
	printf("  CPU Clock         : MCK=%d Hz\n\r", (int)g_ul_current_mck);
	if ((efc_get_flash_access_mode(EFC) & EEFC_FMR_FAM) == EEFC_FMR_FAM) {
		printf("  Flash access mode : 64-bit\n\r");
	} else {
		printf("  Flash access mode : 128-bit\n\r");
	}

	printf("-----------------------------------------------\n\r");
	printf("\n\r");
}

static void dump_all_tc_cv()
{
	int i;
	for (i = 0; i < 3; i++)
		printf("TC0/%d: %u\n\r", i, tc_read_cv(TC0, i));
	for (i = 0; i < 3; i++)
		printf("TC1/%d: %u\n\r", i, tc_read_cv(TC1, i));
}

/**
 * \brief Test Core consumption.
 */
static void test_core(void)
{
	uint8_t uc_key = 0;

	while (1) {
		/* Display menu */
		display_menu_core();

		/* Read a key from console */
		scanf("%c", (char *)&uc_key);

		switch (uc_key) {
		case 't':
			dump_all_tc_cv();
			break;
		/* Configuration */
		case 'f':
		case 'F':
			efc_set_flash_access_mode(EFC, 0); /* 128-bit */
			break;

		case 'g':
		case 'G':
			efc_set_flash_access_mode(EFC, EEFC_FMR_FAM); /* 64-bit */
			break;

		/* Quit test */
		case 'q':
		case 'Q':
			goto test_core_end;

		default:
			puts("This menu does not exist !\r");
			break;
		}       /* Switch */
	}

test_core_end:
	puts(" Exit from core consumption test mode.\r");
}

static void main_vbus_action(bool b_high)
{
	if (b_high)
		udc_attach();
	else
		udc_detach();
}

/**
 * \brief Low power application entry point.
 *
 * \return Unused (ANSI-C compatibility).
 */
int main(void)
{
	/* Initialize the SAM system */
	sysclk_init();
	g_ul_current_mck = sysclk_get_cpu_hz();
	board_init();

	/* Initialize the console uart */
	configure_console();

	/* Output example information */
	puts(STRING_HEADER);

	/* Initialize the chip for the power consumption test */
	init_chip();

	/* Set default clock and re-configure UART */
	set_default_working_clock();
	reconfigure_console(g_ul_current_mck, CONF_UART_BAUDRATE);

	udc_start();
	if (!udc_include_vbus_monitoring())
		main_vbus_action(true);

	/* General SSC for E1 init */
	e1_init_gpio();
	e1_tc_align_init();
	e1_ssc_init();

	/* LIU specific bits */
	idt82_asf_init(&g_idt, SPI, 1);
	idt82_init(&g_idt);

	/* Test core consumption */
	test_core();

	while (1) {
	}
}


/* enable the interface */
bool usb_vendor_e1_enable(void)
{
	printf("%s\n\r", __func__);
	return true;
}

/* disable the interface */
void usb_vendor_e1_disable(void)
{
	printf("%s\n\r", __func__);
}

/* handle a control request directed to an interface */
//bool usb_vendor_e1_setup(void) { }


/* enable the interface */
bool main_cdc_enable(uint8_t port)
{
	printf("%s\n\r", __func__);
	return true;
}

/* disable the interface */
void main_cdc_disable(uint8_t port)
{
	printf("%s\n\r", __func__);
}

void main_cdc_rx_notify(uint8_t port)
{
	printf("%s\n\r", __func__);
}

void main_cdc_set_dtr(uint8_t port, bool b_enable)
{
	printf("%s\n\r", __func__);
}