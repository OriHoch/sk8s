# External Charts

External charts are installed as an independent chart, allowing better separation of sub-charts.

To install a sub-charts use the `helm_upgrade_external_chart.sh` script which handles the passing of values to the external chart.

The external chart will only get the global and the chart specific values.
