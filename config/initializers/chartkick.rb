# Configures global Chartkick and Chart.js defaults for all charts.
#
# This initializer defines visual styling, formatting rules, and behavior
# for charts across the application, ensuring consistency and avoiding
# repetition in view-level configuration.
#
# @author Moisés Reis

# =============================================================
# GLOBAL CHARTKICK OPTIONS
# =============================================================

Chartkick.options = {

  # =============================================================
  # COLOR PALETTE
  # =============================================================

  colors: [
    "rgb(34, 120, 87)",
    "rgb(185, 28, 28)",
    "rgb(37, 99, 235)",
    "rgb(180, 83, 9)",
    "rgb(109, 40, 217)",
    "rgb(17, 94, 89)"
  ],

  # =============================================================
  # FORMATTING & DIMENSIONS
  # =============================================================

  prefix: "",
  thousands: ".",
  decimal: ",",
  height: "500px",

  # =============================================================
  # CHART.JS CONFIGURATION
  # =============================================================

  library: {

    # =============================================================
    # ANIMATION & TYPOGRAPHY
    # =============================================================

    animation: {
      duration: 750
    },

    font: {
      family: "'Source Code Pro'",
      size: 12,
      weight: "400"
    },

    # =============================================================
    # ELEMENT STYLING
    # =============================================================

    elements: {

      bar: {
        borderRadius: 6,
        borderSkipped: false,
        borderWidth: 0
      },

      point: {
        radius: 4,
        hoverRadius: 6,
        borderWidth: 2,
        hoverBorderWidth: 3
      },

      line: {
        borderWidth: 0,
        tension: 0.4
      },

      arc: {
        borderWidth: 2,
        borderRadius: 4,
        hoverBorderWidth: 3
      }
    },

    # =============================================================
    # PLUGINS
    # =============================================================

    plugins: {

      legend: {
        position: "bottom",
        labels: {
          padding: 12,
          usePointStyle: true,
          pointStyle: "rectRounded",
          borderSkipped: true,
          borderWidth: 0,
          font: {
            family: "'Source Code Pro'",
            size: 12,
            weight: "400"
          },
          color: "#8a8a8a"
        }
      },

      tooltip: {
        displayColors: true,
        usePointStyle: true,
        pointStyle: "rectRounded",
        backgroundColor: "#ffffff",
        titleColor: "#333333",
        bodyColor: "#8a8a8a",
        borderColor: "#e9e9e9",
        caretSize: 0,
        borderWidth: 1,
        cornerRadius: 6,
        padding: 12,

        titleFont: {
          family: "'Source Code Pro'",
          size: 12,
          weight: "400"
        },

        bodyFont: {
          family: "'Source Code Pro'",
          size: 12,
          weight: "400"
        }
      }
    },

    # =============================================================
    # SCALES
    # =============================================================

    scales: {
      x: {
        ticks: {
          font: {
            family: "'Source Code Pro'",
            size: 12
          },
          color: "#8a8a8a"
        },
        grid: {
          display: true,
          color: "#e9e9e9"
        }
      },
      y: {
        ticks: {
          font: {
            family: "'Source Code Pro'",
            size: 12
          },
          color: "#8a8a8a"
        },
        grid: {
          display: true,
          color: "#e9e9e9"
        }
      }
    }
  }
}
