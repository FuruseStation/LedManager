from rgbmatrix import RGBMatrixOptions
options = RGBMatrixOptions()

options.rows = 32
options.cols = 64
options.chain_length = 2
options.parallel = 1
options.hardware_mapping = ##MAPPING_TYPE##
options.brightness = 20
options.show_refresh_rate = False
options.limit_refresh_rate_hz = 200
options.gpio_slowdown = ##SLOWDOWN##
options.panel_type = ##PANEL_TYPE##