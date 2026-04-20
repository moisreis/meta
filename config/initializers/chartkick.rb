# Configures global Chartkick and Chart.js defaults for all charts.
#
# This initializer defines visual styling, formatting rules, and behavior
# for charts across the application, ensuring consistency and avoiding
# repetition in view-level configuration.
#
# TABLE OF CONTENTS:
#
# 1. Global Chartkick Options
#   1a. Formatting & Dimensions
#   1b. Color Palette
# 2. Chart.js Library Configuration
#   2a. Animation & Typography
#   2b. Element Styling
#   2c. Plugins
#       2c1. Legend
#       2c2. Tooltip
#   2d. Scales
#
# @author Moisés Reis

# =============================================================
#              1. GLOBAL CHARTKICK OPTIONS
# =============================================================

Chartkick.options = {

  # =============================================================
  #           1b. COLOR PALETTE
  # =============================================================

  # Defines default dataset colors for all charts.
  colors: [
    "rgb(34, 120, 87)",
    "rgb(185, 28, 28)",
    "rgb(37, 99, 235)",
    "rgb(180, 83, 9)",
    "rgb(109, 40, 217)",
    "rgb(17, 94, 89)",
  ],

  # =============================================================
  #        1a. FORMATTING & DIMENSIONS
  # =============================================================

  # Currency prefix (empty for BR formatting handled elsewhere).
  prefix: "",

  # Thousands separator (Brazilian format).
  thousands: ".",

  # Decimal separator (Brazilian format).
  decimal: ",",

  # Default chart height.
  height: "500px",

  # =============================================================
  #        2. CHART.JS LIBRARY CONFIGURATION
  # =============================================================

  library: {

    # =============================================================
    #          2a. ANIMATION & TYPOGRAPHY
    # =============================================================

    # Controls animation timing.
    animation: {
      duration: 750
    },

    # Default font configuration.
    font: {
      family: "'Geist Mono'",
      size: 12,
      weight: '400'
    },

    # =============================================================
    #             2b. ELEMENT STYLING
    # =============================================================

    elements: {

      # Bar chart appearance.
      bar: {
        borderRadius: 6,
        borderSkipped: false,
        borderWidth: 0,
      },

      # Line chart points.
      point: {
        radius: 4,
        hoverRadius: 6,
        borderWidth: 2,
        hoverBorderWidth: 3
      },

      # Line chart curves.
      line: {
        borderWidth: 0,
        tension: 0.4
      },

      # Pie/doughnut arcs.
      arc: {
        borderWidth: 2,
        borderRadius: 4,
        hoverBorderWidth: 3
      }
    },

    # =============================================================
    #                    2c. PLUGINS
    # =============================================================

    plugins: {

      # =============================================================
      #                     2c1. LEGEND
      # =============================================================

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

      # =============================================================
      #                     2c2. TOOLTIP
      # =============================================================

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

        titleFont: {
          family: "'Geist Mono'",
          size: 12,
          weight: '400',
        },

        bodyFont: {
          family: "'Geist Mono'",
          size: 12,
          weight: '400',
        }
      }
    },

    # =============================================================
    #                      2d. SCALES
    # =============================================================

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
