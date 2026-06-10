# frozen_string_literal: true

# config/initializers/chartkick.rb
#
# Configures default options for Chartkick chart rendering.
#
# Sets the application-wide colour palette, locale formatting (thousands
# separator, decimal mark), default chart height, and a full Chart.js
# library override covering animation, typography, element styles, plugin
# configuration (legend, tooltip), and axis scales.
# Chart data queries and view-level options belong in the controller and view layer.
#
# @author  Moisés Reis

Chartkick.options = {

  # == Colour Palette =========================================================

  colors: [
    "rgb(34, 120, 87)",
    "rgb(185, 28, 28)",
    "rgb(37, 99, 235)",
    "rgb(180, 83, 9)",
    "rgb(109, 40, 217)",
    "rgb(17, 94, 89)"
  ],


  # == General Options ========================================================

  prefix:    "",
  thousands: ".",
  decimal:   ",",
  height:    "500px",


  # == Chart.js Library =======================================================

  library: {

    # -- Animation ------------------------------------------------------------

    animation: {
      duration: 750
    },

    # -- Typography -----------------------------------------------------------

    font: {
      family: "'Source Code Pro'",
      size:   12,
      weight: "400"
    },

    # -- Elements -------------------------------------------------------------

    elements: {

      bar: {
        borderRadius: 6,
        borderSkipped: false,
        borderWidth:   0
      },

      point: {
        radius:          4,
        hoverRadius:     6,
        borderWidth:     2,
        hoverBorderWidth: 3
      },

      line: {
        borderWidth: 0,
        tension:     0.4
      },

      arc: {
        borderWidth:     2,
        borderRadius:    4,
        hoverBorderWidth: 3
      }
    },

    # -- Plugins --------------------------------------------------------------

    plugins: {

      legend: {
        position: "bottom",
        labels: {
          padding:       12,
          usePointStyle: true,
          pointStyle:    "rectRounded",
          borderSkipped: true,
          borderWidth:   0,
          font: {
            family: "'Source Code Pro'",
            size:   12,
            weight: "400"
          },
          color: "#8a8a8a"
        }
      },

      tooltip: {
        displayColors:   true,
        usePointStyle:   true,
        pointStyle:      "rectRounded",
        backgroundColor: "#ffffff",
        titleColor:      "#333333",
        bodyColor:       "#8a8a8a",
        borderColor:     "#e9e9e9",
        caretSize:       0,
        borderWidth:     1,
        cornerRadius:    6,
        padding:         12,

        titleFont: {
          family: "'Source Code Pro'",
          size:   12,
          weight: "400"
        },

        bodyFont: {
          family: "'Source Code Pro'",
          size:   12,
          weight: "400"
        }
      }
    },

    # -- Scales ---------------------------------------------------------------

    scales: {

      x: {
        ticks: {
          font:  { family: "'Source Code Pro'", size: 12 },
          color: "#8a8a8a"
        },
        grid: {
          display: true,
          color:   "#e9e9e9"
        }
      },

      y: {
        ticks: {
          font:  { family: "'Source Code Pro'", size: 12 },
          color: "#8a8a8a"
        },
        grid: {
          display: true,
          color:   "#e9e9e9"
        }
      }
    }
  }
}