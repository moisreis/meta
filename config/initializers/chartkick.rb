# === chartkick
#
# @author Moisés Reis
# @added 11/30/2025
# @package *Meta*
# @description This file sets the global visual settings for all charts in the app.
#              It defines how charts look and behave so that every graph follows a
#              unified visual identity across **views**.
# @category *Initializer*
#
# Usage:: - *[What]* It provides the visual defaults applied to every chart in the app.
#         - *[How]* It sends configuration rules directly to the **Chartkick** library.
#         - *[Why]* It keeps all charts consistent and avoids repeating style settings.
#
# Attributes:: - *options* @hash - stores all global Chartkick preferences.
#
Chartkick.options = {

  # Explanation:: This sets the default color palette for all charts. It defines the
  #               sequence of colors used when multiple datasets appear in a graph.
  #               It ensures visual consistency across every chart.
  colors: [
    "#615fff",
    "#91d60c",
    "#9573df",
    "#4faaa0",
    "#609ed2",
    "#00d5be"
  ],

  # Explanation:: This adds a currency prefix to values displayed on charts. It formats
  #               numbers as Brazilian currency and helps users understand values quickly.
  prefix: "",

  # Explanation:: This defines the character used for thousands separation in numbers.
  #               It follows the Brazilian formatting standard to improve readability.
  thousands: ".",

  # Explanation:: This defines the decimal separator. It uses a comma since this is the
  #               default format in Brazilian financial notation.
  decimal: ",",

  # Explanation:: This sets the default height for charts. It ensures a balanced visual
  #               space so charts remain readable on most screen sizes.
  height: "500px",

  # == library
  #
  # @author Moisés Reis
  # @category *Settings*
  #
  # Settings:: This group sets the internal chart behavior and style rules. It controls
  #            animation, font usage, and how elements like bars, lines, and points look.
  #
  # Attributes:: - *library* @hash - holds raw **Chart.js** options that Chartkick passes through.
  #
  library: {

    # Explanation:: This enables smooth transitions when charts load or update. The duration
    #               value defines how long the animation takes, improving user experience.
    animation: {
      duration: 750
    },

    # Explanation:: This sets the default font applied across all chart text. It controls
    #               the family, size and weight so every chart uses the same typography.
    font: {
      family: "'Geist Mono'",
      size: 12,
      weight: '400'
    },

    # Explanation:: This configures the visual appearance of different chart elements.
    #               It ensures bars, points, lines and arcs follow the same design rules.
    elements: {

      # Explanation:: This sets how bars appear in bar charts. Rounded corners make them
      #               modern-looking, and skipping no borders improves shape consistency.
      bar: {
        borderRadius: 6,
        borderSkipped: false,
        borderWidth: 0,
      },

      # Explanation:: This controls how data points appear in line charts. It adjusts their
      #               size, border, and hover behavior to improve clarity for users.
      point: {
        radius: 4,
        hoverRadius: 6,
        borderWidth: 2,
        hoverBorderWidth: 3
      },

      # Explanation:: This defines the look of lines in line charts. It smooths the curve
      #               and sets line thickness for easier visual tracking.
      line: {
        borderWidth: 0,
        tension: 0.4
      },

      # Explanation:: This controls arcs in pie and doughnut charts. It sets border rules
      #               and hover behavior so slices appear clean and well-defined.
      arc: {
        borderWidth: 2,
        borderRadius: 4,
        hoverBorderWidth: 3
      }
    },

    # == plugins
    #
    # @category *Settings*
    #
    # Settings:: This section customizes built-in plugins like legends and tooltips. It
    #            ensures labels and hover information are readable and consistent.
    #
    # Attributes:: - *plugins* @hash - configures optional helpers that improve chart UX.
    #
    plugins: {

      # Explanation:: This sets the position and appearance of the chart legend. It defines
      #               how dataset labels look so users can easily identify each color.
      legend: {
        position: 'bottom',
        labels: {
          padding: 12,
          usePointStyle: true,
          pointStyle: 'rectRounded',
          borderSkipped: true,
          borderWidth: 0,
          font: {
            family: "'Geist Mono'",
            size: 12,
            weight: '400'
          },
          color: '#8a8a8a'
        }
      },

      # Explanation:: This defines how tooltips appear when a user hovers over a chart.
      #               It controls colors, borders and spacing to improve visibility.
      tooltip: {
        displayColors: true,
        usePointStyle: true,
        pointStyle: 'rectRounded',
        backgroundColor: '#ffffff',
        titleColor: '#333333',
        bodyColor: '#8a8a8a',
        borderColor: '#e9e9e9',
        caretSize: 0,
        borderWidth: 1,
        cornerRadius: 6,
        padding: 12,

        # Explanation:: This sets the font used in tooltip titles. It keeps titles readable
        #               and aligned with the app's typographic style.
        titleFont: {
          family: "'Geist Mono'",
          size: 12,
          weight: '400',
          color: '#333333',
        },

        # Explanation:: This sets the font for tooltip body text. It follows the same style
        #               rules to maintain visual balance inside the tooltip box.
        bodyFont: {
          family: "'Geist Mono'",
          size: 12,
          weight: '400',
          color: '#8a8a8a',
        }
      }
    },

    # Explanation:: This sets how the X and Y axes look. It controls fonts, colors and grid
    #               lines so charts stay readable and uncluttered.
    scales: {
      x: {
        ticks: {
          font: {
            family: "'Geist Mono'",
            size: 12
          },
          color: '#8a8a8a',
        },
        grid: {
          display: true,
          color: '#e9e9e9',
        }
      },
      y: {
        ticks: {
          font: {
            family: "'Geist Mono'",
            size: 12
          },
          color: '#8a8a8a'
        },
        grid: {
          display: true,
          color: '#e9e9e9',
        }
      }
    }
  }
}