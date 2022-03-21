module Constants
  COLOURS = {
    white:      { red: 1, green: 1, blue: 1 },
    black:      { red: 0, green: 0, blue: 0 },
    red:        { red: 0.95, green: 0.8, blue: 0.8 },
    red_dark:   { red: 0.79, green: 0.03, blue: 0.07 },
    green:      { red: 0.85, green: 0.92, blue: 0.83 },
    green_dark: { red: 0.42, green: 0.65, blue: 0.33 },
    blue:       { red: 0.82, green: 0.88, blue: 0.95 },
    blue_dark:  { red: 0.25, green: 0.53, blue: 0.77 }
  }.freeze

  CANDLESTICK_GRANULARITY_IN_SECONDS = {
    'S5'  => 5,
    'S10' => 10,
    'S15' => 15,
    'S30' => 30,
    'M1'  => 60,
    'M2'  => 120,
    'M3'  => 180,
    'M4'  => 240,
    'M5'  => 300,
    'M10' => 600,
    'M15' => 900,
    'M30' => 1_800,
    'H1'  => 3_600,
    'H2'  => 7_200,
    'H3'  => 10_800,
    'H4'  => 14_400,
    'H6'  => 21_600,
    'H8'  => 28_800,
    'H12' => 43_200,
    'D'   => 86_400,
    'W'   => 604_800,
    'M'   => 2_678_400
  }

  INSTRUMENTS = {
    # Forex.
    'AUD_CAD' => {
      'instrument'  => 'AUD_CAD',
      'worker_code' => '000',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'AUD_CHF' => {
      'instrument'  => 'AUD_CHF',
      'worker_code' => '002',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'AUD_HKD' => {
      'instrument'  => 'AUD_HKD',
      'worker_code' => '004',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'AUD_JPY' => {
      'instrument'  => 'AUD_JPY',
      'worker_code' => '006',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'AUD_NZD' => {
      'instrument'  => 'AUD_NZD',
      'worker_code' => '008',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'AUD_SGD' => {
      'instrument'  => 'AUD_SGD',
      'worker_code' => '010',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'AUD_USD' => {
      'instrument'  => 'AUD_USD',
      'worker_code' => '012',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'CAD_CHF' => {
      'instrument'  => 'CAD_CHF',
      'worker_code' => '014',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'CAD_HKD' => {
      'instrument'  => 'CAD_HKD',
      'worker_code' => '016',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'CAD_JPY' => {
      'instrument'  => 'CAD_JPY',
      'worker_code' => '018',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'CAD_SGD' => {
      'instrument'  => 'CAD_SGD',
      'worker_code' => '020',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'CHF_HKD' => {
      'instrument'  => 'CHF_HKD',
      'worker_code' => '022',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'CHF_JPY' => {
      'instrument'  => 'CHF_JPY',
      'worker_code' => '024',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'CHF_ZAR' => {
      'instrument'  => 'CHF_ZAR',
      'worker_code' => '026',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_AUD' => {
      'instrument'  => 'EUR_AUD',
      'worker_code' => '028',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_CAD' => {
      'instrument'  => 'EUR_CAD',
      'worker_code' => '030',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_CHF' => {
      'instrument'  => 'EUR_CHF',
      'worker_code' => '032',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_CZK' => {
      'instrument'  => 'EUR_CZK',
      'worker_code' => '034',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_DKK' => {
      'instrument'  => 'EUR_DKK',
      'worker_code' => '036',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_GBP' => {
      'instrument'  => 'EUR_GBP',
      'worker_code' => '038',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_HKD' => {
      'instrument'  => 'EUR_HKD',
      'worker_code' => '040',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_HUF' => {
      'instrument'  => 'EUR_HUF',
      'worker_code' => '042',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'EUR_JPY' => {
      'instrument'  => 'EUR_JPY',
      'worker_code' => '044',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'EUR_NOK' => {
      'instrument'  => 'EUR_NOK',
      'worker_code' => '046',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_NZD' => {
      'instrument'  => 'EUR_NZD',
      'worker_code' => '048',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_PLN' => {
      'instrument'  => 'EUR_PLN',
      'worker_code' => '050',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_SEK' => {
      'instrument'  => 'EUR_SEK',
      'worker_code' => '052',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_SGD' => {
      'instrument'  => 'EUR_SGD',
      'worker_code' => '054',
      'pip_size'    => 0.0001
    },
    'EUR_TRY' => {
      'instrument'  => 'EUR_TRY',
      'worker_code' => '056',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_USD' => {
      'instrument'  => 'EUR_USD',
      'worker_code' => '058',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'EUR_ZAR' => {
      'instrument'  => 'EUR_ZAR',
      'worker_code' => '060',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'GBP_AUD' => {
      'instrument'  => 'GBP_AUD',
      'worker_code' => '062',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'GBP_CAD' => {
      'instrument'  => 'GBP_CAD',
      'worker_code' => '064',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'GBP_CHF' => {
      'instrument'  => 'GBP_CHF',
      'worker_code' => '066',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'GBP_HKD' => {
      'instrument'  => 'GBP_HKD',
      'worker_code' => '068',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'GBP_JPY' => {
      'instrument'  => 'GBP_JPY',
      'worker_code' => '070',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'GBP_NZD' => {
      'instrument'  => 'GBP_NZD',
      'worker_code' => '072',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'GBP_PLN' => {
      'instrument'  => 'GBP_PLN',
      'worker_code' => '074',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'GBP_SGD' => {
      'instrument'  => 'GBP_SGD',
      'worker_code' => '076',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'GBP_USD' => {
      'instrument'  => 'GBP_USD',
      'worker_code' => '078',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'GBP_ZAR' => {
      'instrument'  => 'GBP_ZAR',
      'worker_code' => '080',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'HKD_JPY' => {
      'instrument'  => 'HKD_JPY',
      'worker_code' => '082',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'NZD_CAD' => {
      'instrument'  => 'NZD_CAD',
      'worker_code' => '084',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'NZD_CHF' => {
      'instrument'  => 'NZD_CHF',
      'worker_code' => '086',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'NZD_HKD' => {
      'instrument'  => 'NZD_HKD',
      'worker_code' => '088',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'NZD_JPY' => {
      'instrument'  => 'NZD_JPY',
      'worker_code' => '090',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'NZD_SGD' => {
      'instrument'  => 'NZD_SGD',
      'worker_code' => '092',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'NZD_USD' => {
      'instrument'  => 'NZD_USD',
      'worker_code' => '094',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'SGD_CHF' => {
      'instrument'  => 'SGD_CHF',
      'worker_code' => '096',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'SGD_HKD' => {
      'instrument'  => 'SGD_HKD',
      'worker_code' => '098',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'SGD_JPY' => {
      'instrument'  => 'SGD_JPY',
      'worker_code' => '100',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'TRY_JPY' => {
      'instrument'  => 'TRY_JPY',
      'worker_code' => '102',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'USD_CAD' => {
      'instrument'  => 'USD_CAD',
      'worker_code' => '104',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_CHF' => {
      'instrument'  => 'USD_CHF',
      'worker_code' => '106',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_CNH' => {
      'instrument'  => 'USD_CNH',
      'worker_code' => '108',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_CZK' => {
      'instrument'  => 'USD_CZK',
      'worker_code' => '110',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_DKK' => {
      'instrument'  => 'USD_DKK',
      'worker_code' => '112',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_HKD' => {
      'instrument'  => 'USD_HKD',
      'worker_code' => '114',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_HUF' => {
      'instrument'  => 'USD_HUF',
      'worker_code' => '116',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'USD_INR' => {
      'instrument'  => 'USD_INR',
      'worker_code' => '118',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'USD_JPY' => {
      'instrument'  => 'USD_JPY',
      'worker_code' => '120',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'USD_MXN' => {
      'instrument'  => 'USD_MXN',
      'worker_code' => '122',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_NOK' => {
      'instrument'  => 'USD_NOK',
      'worker_code' => '124',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_PLN' => {
      'instrument'  => 'USD_PLN',
      'worker_code' => '126',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_SAR' => {
      'instrument'  => 'USD_SAR',
      'worker_code' => '128',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_SEK' => {
      'instrument'  => 'USD_SEK',
      'worker_code' => '130',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_SGD' => {
      'instrument'  => 'USD_SGD',
      'worker_code' => '132',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_THB' => {
      'instrument'  => 'USD_THB',
      'worker_code' => '134',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'USD_TRY' => {
      'instrument'  => 'USD_TRY',
      'worker_code' => '136',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'USD_ZAR' => {
      'instrument'  => 'USD_ZAR',
      'worker_code' => '138',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'ZAR_JPY' => {
      'instrument'  => 'ZAR_JPY',
      'worker_code' => '140',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },

    # Metals.
    'XAG_AUD' => {
      'instrument'  => 'XAG_AUD',
      'worker_code' => '600',
      'pip_size'    => 0.0001
    },
    'XAG_CAD' => {
      'instrument'  => 'XAG_CAD',
      'worker_code' => '602',
      'pip_size'    => 0.0001
    },
    'XAG_CHF' => {
      'instrument'  => 'XAG_CHF',
      'worker_code' => '604',
      'pip_size'    => 0.0001
    },
    'XAG_EUR' => {
      'instrument'  => 'XAG_EUR',
      'worker_code' => '606',
      'pip_size'    => 0.0001
    },
    'XAG_GBP' => {
      'instrument'  => 'XAG_GBP',
      'worker_code' => '608',
      'pip_size'    => 0.0001
    },
    'XAG_HKD' => {
      'instrument'  => 'XAG_HKD',
      'worker_code' => '610',
      'pip_size'    => 0.0001
    },
    'XAG_JPY' => {
      'instrument'  => 'XAG_JPY',
      'worker_code' => '612',
      'pip_size'    => 1.0
    },
    'XAG_NZD' => {
      'instrument'  => 'XAG_NZD',
      'worker_code' => '614',
      'pip_size'    => 0.0001
    },
    'XAG_SGD' => {
      'instrument'  => 'XAG_SGD',
      'worker_code' => '616',
      'pip_size'    => 0.0001
    },
    'XAG_USD' => {
      'instrument'  => 'XAG_USD',
      'worker_code' => '618',
      'pip_size'    => 0.0001
    },
    'XAU_AUD' => {
      'instrument'  => 'XAU_AUD',
      'worker_code' => '620',
      'pip_size'    => 0.01
    },
    'XAU_CAD' => {
      'instrument'  => 'XAU_CAD',
      'worker_code' => '622',
      'pip_size'    => 0.01
    },
    'XAU_CHF' => {
      'instrument'  => 'XAU_CHF',
      'worker_code' => '624',
      'pip_size'    => 0.01
    },
    'XAU_EUR' => {
      'instrument'  => 'XAU_EUR',
      'worker_code' => '626',
      'pip_size'    => 0.01
    },
    'XAU_GBP' => {
      'instrument'  => 'XAU_GBP',
      'worker_code' => '628',
      'pip_size'    => 0.01
    },
    'XAU_HKD' => {
      'instrument'  => 'XAU_HKD',
      'worker_code' => '630',
      'pip_size'    => 0.01
    },
    'XAU_JPY' => {
      'instrument'  => 'XAU_JPY',
      'worker_code' => '632',
      'pip_size'    => 1.0
    },
    'XAU_NZD' => {
      'instrument'  => 'XAU_NZD',
      'worker_code' => '634',
      'pip_size'    => 0.01
    },
    'XAU_SGD' => {
      'instrument'  => 'XAU_SGD',
      'worker_code' => '636',
      'pip_size'    => 0.01
    },
    'XAU_USD' => {
      'instrument'  => 'XAU_USD',
      'worker_code' => '638',
      'pip_size'    => 0.01
    },
    'XAU_XAG' => {
      'instrument'  => 'XAU_XAG',
      'worker_code' => '640',
      'pip_size'    => 0.01
    },
    'XCU_USD' => {
      'instrument'  => 'XCU_USD',
      'worker_code' => '642',
      'pip_size'    => 0.01
    },
    'XPD_USD' => {
      'instrument'  => 'XPD_USD',
      'worker_code' => '644',
      'pip_size'    => 0.01
    },
    'XPT_USD' => {
      'instrument'  => 'XPT_USD',
      'worker_code' => '646',
      'pip_size'    => 0.01
    },

    # Bonds.
    'DE10YB_EUR' => {
      'instrument'  => 'DE10YB_EUR',
      'worker_code' => '700',
      'pip_size'    => 0.01
    },
    'UK10YB_GBP' => {
      'instrument'  => 'UK10YB_GBP',
      'worker_code' => '702',
      'pip_size'    => 0.01
    },
    'USB02Y_USD' => {
      'instrument'  => 'USB02Y_USD',
      'worker_code' => '704',
      'pip_size'    => 0.01
    },
    'USB05Y_USD' => {
      'instrument'  => 'USB05Y_USD',
      'worker_code' => '706',
      'pip_size'    => 0.01
    },
    'USB10Y_USD' => {
      'instrument'  => 'USB10Y_USD',
      'worker_code' => '708',
      'pip_size'    => 0.01
    },
    'USB30Y_USD' => {
      'instrument'  => 'USB30Y_USD',
      'worker_code' => '710',
      'pip_size'    => 0.01
    },

    # Indices.
    'AU200_AUD' => {
      'instrument'  => 'AU200_AUD',
      'worker_code' => '800',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'CH20_CHF' => {
      'instrument'  => 'CH20_CHF',
      'worker_code' => '802',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'CN50_USD' => {
      'instrument'  => 'CN50_USD',
      'worker_code' => '804',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'DE30_EUR' => {
      'instrument'  => 'DE30_EUR',
      'worker_code' => '806',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'EU50_EUR' => {
      'instrument'  => 'EU50_EUR',
      'worker_code' => '808',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'FR40_EUR' => {
      'instrument'  => 'FR40_EUR',
      'worker_code' => '810',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'HK33_HKD' => {
      'instrument'  => 'HK33_HKD',
      'worker_code' => '812',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'IN50_USD' => {
      'instrument'  => 'IN50_USD',
      'worker_code' => '814',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'JP225_USD' => {
      'instrument'  => 'JP225_USD',
      'worker_code' => '816',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'NL25_EUR' => {
      'instrument'  => 'NL25_EUR',
      'worker_code' => '818',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'SG30_SGD' => {
      'instrument'  => 'SG30_SGD',
      'worker_code' => '820',
      'pip_size'    => 0.1,
      'sheet'       => ''
    },
    'UK100_GBP' => {
      'instrument'  => 'UK100_GBP',
      'worker_code' => '822',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'US2000_USD' => {
      'instrument'  => 'US2000_USD',
      'worker_code' => '824',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'US30_USD' => {
      'instrument'  => 'US30_USD',
      'worker_code' => '826',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'NAS100_USD' => {
      'instrument'  => 'NAS100_USD',
      'worker_code' => '828',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'SPX500_USD' => {
      'instrument'  => 'SPX500_USD',
      'worker_code' => '830',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },
    'TWIX_USD' => {
      'instrument'  => 'TWIX_USD',
      'worker_code' => '832',
      'pip_size'    => 1.0,
      'sheet'       => ''
    },

    # Commodities.
    'BCO_USD' => {
      'instrument'  => 'BCO_USD',
      'worker_code' => '900',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'CORN_USD' => {
      'instrument'  => 'CORN_USD',
      'worker_code' => '902',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'NATGAS_USD' => {
      'instrument'  => 'NATGAS_USD',
      'worker_code' => '908',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'SOYBN_USD' => {
      'instrument'  => 'SOYBN_USD',
      'worker_code' => '910',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'SUGAR_USD' => {
      'instrument'  => 'SUGAR_USD',
      'worker_code' => '914',
      'pip_size'    => 0.0001,
      'sheet'       => ''
    },
    'WHEAT_USD' => {
      'instrument'  => 'WHEAT_USD',
      'worker_code' => '928',
      'pip_size'    => 0.01,
      'sheet'       => ''
    },
    'WTICO_USD' => {
      'instrument'  => 'WTICO_USD',
      'worker_code' => '930',
      'pip_size'    => 0.01,
      'sheet'       => ''
    }
  }.freeze
end
