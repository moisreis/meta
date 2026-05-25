# Configures default options for Chartkick chart rendering.
#
# Sets the application-wide colour palette, locale formatting
# for number display (thousands separator, decimal mark),
# default chart height, and a full Chart.js library override
# covering animation, typography, element styles, plugin
# configuration (legend, tooltip), and axis scales.
#
# This file does not define chart data queries or view-level
# chart options. Those belong in the controller and view layer.
#
# @author Moisés Reis

Chartkick.options = {

  # =============================================================
  #                        COLOUR PALETTE
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
  #                       GENERAL OPTIONS
  # =============================================================

  prefix: "",
  thousands: ".",
  decimal: ",",
  height: "500px",

  # =============================================================
  #                      CHART.JS LIBRARY
  # =============================================================

  library: {

    # --- ANIMATION -----------------------------------------------

    animation: {
      duration: 750
    },

    # --- TYPOGRAPHY ----------------------------------------------

    font: {
      family: "'Source Code Pro'",
      size: 12,
      weight: "400"
    },

    # --- ELEMENTS ------------------------------------------------

    elements: {

      # --- BAR ---

      bar: {
        borderRadius: 6,
        borderSkipped: false,
        borderWidth: 0
      },

      # --- POINT ---

      point: {
        radius: 4,
        hoverRadius: 6,
        borderWidth: 2,
        hoverBorderWidth: 3
      },

      # --- LINE ---

      line: {
        borderWidth: 0,
        tension: 0.4
      },

      # --- ARC ---

      arc: {
        borderWidth: 2,
        borderRadius: 4,
        hoverBorderWidth: 3
      }
    },

    # --- PLUGINS -------------------------------------------------

    plugins: {

      # --- LEGEND ---

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

      # --- TOOLTIP ---

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

    # --- SCALES --------------------------------------------------

    scales: {

      # --- X AXIS ---

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

      # --- Y AXIS ---

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