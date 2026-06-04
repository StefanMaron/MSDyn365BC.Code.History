/*! Copyright (C) Microsoft Corporation. All rights reserved. */
"use strict";

var chart = null,
  stackIndex;

// Taken from https://api.highcharts.com/highcharts/series.line.marker
var DEFAULT_MARKER_RADIUS = 4;
var HOVER_MARKER_RADIUS = DEFAULT_MARKER_RADIUS + 2;
// Cannot be 0 or highcharts will not render the marker and the point will not be accessible to screenreaders
var HIDDEN_MARKER_RADIUS = 0.0001;
// We do not provide a title for the chart, so modify the default "beforeChartFormat" screen reader text template to remove the <h5> containing the chart title. See #378209
// The original default template can be found here: https://api.highcharts.com/highcharts/accessibility.screenReaderSection.beforeChartFormat
var BEFORE_CHART_FORMAT_TEMPLATE =
  "<div>{typeDescription}</div><div>{chartSubtitle}</div><div>{chartLongdesc}</div><div>{playAsSoundButton}</div><div>{viewTableButton}</div><div>{xAxisDescription}</div><div>{yAxisDescription}</div><div>{annotationsTitle}{annotationsList}</div>";

// Initialization of the control add-in.
// Note: This function is called by the manifest after loading the control add-in.
function Initialize() {
  window.addEventListener('resize', function () {
    var width = window.document.documentElement.getBoundingClientRect().width;
    var height = window.document.documentElement.getBoundingClientRect().height;

    onChartSizeChanged(width, height);
  });

  raiseAddInReady();
}

function controlAddIn() {
  return document.getElementById('controlAddIn');
}

// Update the chart with the supplied chart data.
// Note: This function is called from the application code.
function Update(chartData) {
  // If a tooltip from an existing chart is visible we must hide it
  if (chart != null && chart.tooltip != null && !chart.tooltip.isHidden) {
    // Start hiding it
    chart.tooltip.hide();

    // Wait for the tooltip's hide timer to fire
    // - otherwise we get a crash when the tooltip
    //   timer fires and references the tooltip,
    //   which would have been deleted before the
    //   timer fires if we don't wait for it.
    createUIWhenToolTipIsHidden(chartData);
  } else {
    createUI(chartData);
  }
}

// Refresh the control add-in.
function Refresh() {
  raiseRefresh();
}

// Event will be fired when the control add-in is ready for communication through its API.
function raiseAddInReady() {
  Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("AddInReady", null);
}

// Event raised when the control add-in should be refreshed.
function raiseRefresh() {
  Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("Refresh", null);
}

// Event raised when a data point has been clicked.
function raiseDataPointClicked(point) {
  Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
    "DataPointClicked",
    [point],
    true
  );
}

// Create a new chart and initialize it with the supplied data.
// If an existing chart is available, this function waits for the
// tooltip of the existing chart to be hidden before creating
// the new chart.
function createUIWhenToolTipIsHidden(chartData) {
  if (!chart.tooltip.isHidden) {
    window.setTimeout(function () {
      createUIWhenToolTipIsHidden(chartData);
      chartData = null;
    }, 100);
  } else {
    createUI(chartData);
  }
}

// Create a new chart and initialize it with the supplied data.
// If the data does not contain valid chart data it will create
// a text block showing a message about missing data instead of
// creating the chart.
function createUI(chartData) {
  if (chart != null) {
    chart.destroy();
    chart = null;
  }

  // Remove any existing content
  controlAddIn().innerHTML = '';

  if (validateChartData(chartData)) {
    initializeChartLanguage(chartData);
    createChart(chartData);
  }
}

// Verify that the chart data contains valid information.
function validateChartData(chartData) {
  if (!validateData(chartData)) {
    return false;
  }

  if (!validateYAxisRange(chartData)) {
    return false;
  }

  return true;
}

// Verify that the chart data contains data.
function validateData(chartData) {
  if (
    chartData.XDimensionColumn == null ||
    chartData.XDimensionColumn.ColumnName == null ||
    chartData.Measures == null ||
    chartData.Measures.length == 0 ||
    chartData.DataTable == null ||
    chartData.DataTable.length == 0 ||
    chartDataContainsEmptyPie(chartData)
  ) {
    createMessage(chartData.Resources.NoDataAvailable);
    return false;
  }

  return true;
}

// Verify that the chart data contains valid y-axis range.
function validateYAxisRange(chartData) {
  // Did we receive a valid y-axis range?
  if (
    !isNaN(chartData.YAxisMinimum) &&
    !isNaN(chartData.YAxisMaximum) &&
    chartData.YAxisMinimum >= chartData.YAxisMaximum
  ) {
    createMessage(chartData.Resources.YAxisRangeInvalid);
    return false;
  }

  return true;
}

// Create a DIV containing the specified message text.
function createMessage(text) {
  var element = document.createElement("div");
  element.className = getMessageClassName();
  var spanElement = document.createElement("span");
  spanElement.innerText = text;
  element.appendChild(spanElement);

  controlAddIn().appendChild(element);
}

// Initialize the month, short month, and weekday names of the chart.
function initializeChartLanguage(chartData) {
  Highcharts.setOptions({
    lang: {
      months: chartData.Resources.MonthNames,
      shortMonths: chartData.Resources.ShortMonthNames,
      weekdays: chartData.Resources.WeekdayNames,
      accessibility: chartData.Resources.Accessibility,
    },
  });
}

function createPalette() {
  if (useModena365Theme()) {
    return [
      "rgba(80, 93, 109, 0.8)", // 1.  80% Ash grey
      "rgba(167, 173, 182, 0.8)", // 2.  80% Ash grey 50%
      "rgba(0, 128, 137, 0.8)", // 3.  80% Tertiary shade 2
      "rgba(0, 183, 195, 0.8)", // 4.  80% Aqua
      "rgba(166, 230, 234, 0.8)", // 5.  80% Aqua 35%
      "rgba(201, 196, 114, 0.8)", // 6.  80% Yellow
      "rgba(136, 206, 129, 0.8)", // 7.  80% Green
      "rgba(233, 119, 104, 0.8)", // 8.  80% Red
      "rgba(117, 181, 231, 0.8)", // 9.  80% Blue
      "rgba(133, 141, 153, 0.8)", // 10. 80% Ash grey 70%
      "rgba(229, 231, 233, 0.8)", // 11. 80% Ash grey 15%
      "rgba(89, 204, 180, 0.8)", // 12. 80% Light green
      "rgba(117, 216, 231, 0.8)", // 13. 80% Sky
      "rgba(238, 234, 134, 0.8)", // 14. 80% Egg
      "rgba(232, 158, 99, 0.8)", // 15. 80% Orange
      "rgba(219, 189, 235, 0.8)", // 16. 80% Violet
      "rgba(203, 206, 211, 0.8)", // 17. 80% Ash grey 30%
      "rgba(57, 178, 148, 0.8)", // 18. 80% Teal
      "rgba(115, 186, 90, 0.8)", // 19. 80% Green2
      "rgba(230, 94, 109, 0.8)", // 20. 80% Scarlet
    ];
  }

  return [
    "rgba(15, 111, 198, 0.8)", // 80% Blue
    "rgba(195, 38, 12, 0.8)", // 80% Red
    "rgba(84, 158, 57, 0.8)", // 80% Green
    "rgba(155, 87, 211, 0.8)", // 80% Purple
    "rgba(62, 204, 180, 0.8)", // 80% Turquoise
    "rgba(255, 185, 29, 0.8)", // 80% Yellow
    "rgba(180, 21, 109, 0.8)", // 80% Pink
    "rgba(255, 132, 39, 0.8)", // 80% Orange
    "rgba(177, 204, 41, 0.8)", // 80% Lime
    "rgba(41, 204, 82, 0.8)", // 80% Teal
    "rgba(36, 36, 102, 0.8)", // 80% DarkBlue
    "rgba(229, 115, 229, 0.8)", // 80% LightPurple
  ];
}

// Gets whether the tooltips should be enabled.
function getToolTipEnabled() {
  return true;
}

function getTooltipHeaderCaption(chartData) {
  var caption = chartData.XDimensionColumn.Caption;
  if (caption == null) {
    caption = chartData.XDimensionColumn.ColumnName;
  }

  return caption;
}

// Get the tooltip header format. A tooltip will contian one of
// these headers.
function getToolTipHeaderFormat(chartData) {
  var caption = getTooltipHeaderCaption(chartData);
  return (
    '<span class="addInToolTipHeader">' +
    caption +
    ": {point.key}</span><table>"
  );
}

// Get the tool tip point format. A tooltip will contain one of
// these for each serie in the chart.
function getToolTipPointFormat() {
  return (
    "<tr>" +
    '<td class="addInToolTipPointName"><span style="color:{series.color}">●</span> {series.name}: </td>' +
    '<td class="addInToolTipPointValue">{point.y}</td>' +
    "</tr>"
  );
}

// Get the tooltip footer format. A tooltip will contain one of
// these footers.
function getToolTipFooterFormat() {
  return "</table>";
}

// Create a new chart and initialize it with the supplied data.
function createChart(chartData) {
  stackIndex = 0;

  var xAxisType = getXAxisType(chartData);
  var legendEnabled = true;
  var verticalAlignmentLegend = getVerticalAlignmentLegend(chartData);
  chart = new Highcharts.Chart(
    {
      accessibility: {
        point: {
          descriptionFormatter: function (point) {
            var caption = getTooltipHeaderCaption(chartData);
            var value =
              point.series.type === "pie"
                ? Math.round(point.percentage) + "%"
                : point.y;

            return (
              caption +
              ": " +
              point.name +
              ", " +
              point.series.name +
              ": " +
              value
            );
          },
        },
        keyboardNavigation: {
          order: getKeyboardOrder(legendEnabled, verticalAlignmentLegend),
        },
        screenReaderSection: {
          beforeChartFormat: BEFORE_CHART_FORMAT_TEMPLATE,
        },
      },
      chart: {
        renderTo: "controlAddIn",
        type: getDefaultSerieType(chartData),
        polar: getPolarSeriesType(chartData),
      },
      colors: createPalette(),
      credits: {
        enabled: false,
      },
      exporting: {
        enabled: false,
      },
      legend: {
        align: getHorizontalAlignmentLegend(chartData),
        borderWidth: 0,
        enabled: legendEnabled,
        itemStyle: {
          fontWeight: "normal",
        },
        margin: 20,
        navigation: {
          style: {
            fontWeight: "normal",
          },
        },
        verticalAlign: verticalAlignmentLegend,
      },
      plotOptions: {
        area: {
          stacking: getAreaSeriesStacking(chartData),
          trackByArea: true,
        },
        column: {
          borderWidth: 1,
          groupPadding: 0.1,
          pointPadding: 0,
          stacking: getColumnSeriesStacking(chartData),
        },
        funnel: {
          dataLabels: {
            connectorWidth: 0,
            distance: 10,
          },
        },
        pie: {
          dataLabels: {
            connectorWidth: 0,
            distance: 10,
            enabled: false,
          },
          showInLegend: true,
        },
        series: {
          animation: true,
          cursor: "pointer",
          point: {
            events: {
              click: onPointClick,
              mouseOver: function () {
                var redrawChart = false;
                this.update(
                  {
                    color: this.color,
                  },
                  redrawChart
                );
              },
            },
          },
          stickyTracking: false,
        },
      },
      series: getSeries(chartData, xAxisType),
      title: {
        text: null,
      },
      tooltip: {
        enabled: getToolTipEnabled(),
        footerFormat: getToolTipFooterFormat(),
        headerFormat: getToolTipHeaderFormat(chartData),
        hideDelay: 0,
        pointFormat: getToolTipPointFormat(),
        backgroundColor: "rgba(247, 247, 247, .9)",
        borderWidth: 0,
        shared: true,
        useHTML: true,
      },
      xAxis: {
        minTickInterval: getXAxisMinTickInterval(xAxisType),
        type: xAxisType,
      },
      yAxis: {
        min: getYAxisMin(chartData),
        max: getYAxisMax(chartData),
        reversedStacks: false,
        title: {
          text: null,
        },
      },
    },
    function (chart) {
      var svgElement = chart.renderer.box;
      var descElements = svgElement.getElementsByTagName("desc");

      for (var i = descElements.length - 1; i >= 0; i--) {
        // This element says "Created by Highcharts Version <Version numbr>"
        // The element cannot be removed because the accessibility script references it
        // but the innerHTML can be cleared
        descElements[i].innerHTML = "";
      }
    }
  );

  // Make chart non-focusable
  chart.container.querySelectorAll("svg").forEach(svg => {
    svg.setAttribute("focusable", "false")
  });

  var width = chart.container.getBoundingClientRect().width;
  var height = chart.container.getBoundingClientRect().height;

  // Update the size-dependent properties
  if (width > 0 && height > 0) {
    onSizeChanged(width, height);
  }
}

// Get the data series for the chart.
function getSeries(chartData, xAxisType) {
  var series = new Array();

  for (var i = 0; i < chartData.Measures.length; i++) {
    var measure = chartData.Measures[i];
    var stacking = getSerieStacking(chartData, measure);
    var stack;

    if (stacking != null) {
      stack = stacking;
    } else {
      stack = stackIndex++;
    }

    series[i] = {
      data: getSerieData(chartData, measure, xAxisType),
      innerSize: getSerieInnerSize(chartData, measure),
      lineWidth: getSerieLineWidth(chartData, measure),
      marker: getSerieMarker(chartData, measure),
      name: measure,
      stack: stack,
      step: getSerieLineStep(chartData, measure),
      type: getSerieType(chartData, measure),
    };
  }

  return series;
}

// Get the data of a single serie in the chart.
function getSerieData(chartData, measure, xAxisType) {
  var returnValue = new Array();
  for (var i = 0; i < chartData.DataTable.length; i++) {
    var data = chartData.DataTable[i][chartData.XDimensionColumn.ColumnName];
    if (xAxisType == "datetime") {
      returnValue[i] = {
        x: Date.parse(data),
        y: chartData.DataTable[i][measure],
      };
    } else {
      returnValue[i] = {
        name: data,
        y: chartData.DataTable[i][measure],
      };
    }
  }

  return returnValue;
}

// Get the default type (column, pie, etc) for the series in the chart.
function getDefaultSerieType(chartData) {
  return getChartType(chartData.DefaultType);
}

// Get the type (column, pie, etc) for a single serie in the chart.
function getSerieType(chartData, measure) {
  return getChartType(chartData.MeasureTypes[measure]);
}

// Get the chart type from the measure type of the chart data.
function getChartType(type) {
  switch (type) {
    case 0: // Point
    case 3: // Line
    case 5: // StepLine
      return "line";

    case 10: // Column
    case 11: // StackedColumn
    case 12: // StackedColumn100
      return "column";

    case 13: // Area
    case 15: // StackedArea
    case 16: // StackedArea100
      return "area";

    case 17: // Pie
    case 18: // Doughnut
      return "pie";

    case 25: // Radar
      return "area";

    case 33: // Funnel
      return "funnel";
  }

  throw "unsupported chart type";
}

// Get the stacking type of the first column serie that is using stacking.
function getColumnSeriesStacking(chartData) {
  for (var i = 0; i < chartData.Measures.length; i++) {
    var measure = chartData.Measures[i];
    var measureType = chartData.MeasureTypes[measure];
    switch (measureType) {
      case 11: // StackedColumn
      case 12: // StackedColumn100
        return getSerieStacking(chartData, chartData.Measures[i]);
    }
  }

  return null;
}

// Get the stacking type of the first area serie that is using stacking.
function getAreaSeriesStacking(chartData) {
  for (var i = 0; i < chartData.Measures.length; i++) {
    var measure = chartData.Measures[i];
    var measureType = chartData.MeasureTypes[measure];
    switch (measureType) {
      case 15: // StackedArea
      case 16: // StackedArea100
        return getSerieStacking(chartData, chartData.Measures[i]);
    }
  }

  return null;
}

// Get the stacking type of a single serie.
function getSerieStacking(chartData, measure) {
  var measureType = chartData.MeasureTypes[measure];
  switch (measureType) {
    case 11: // StackedColumn
    case 15: // StackedArea
      return "normal";

    case 12: // StackedColumn100
    case 16: // StackedArea100
      return "percent";
  }

  return null;
}

// Get the line width of a single serie. If not line is
// requested for the serie, 0 (zero) is returned.
function getSerieLineWidth(chartData, measure) {
  var measureType = chartData.MeasureTypes[measure];
  switch (measureType) {
    case 0: // Point
    case 13: // Area
    case 15: // StackedArea
    case 16: // StackedArea100
      return 0;
  }

  return 2;
}

// Get whether a single serie need line stepping.
// Only used for step line charts.
function getSerieLineStep(chartData, measure) {
  var measureType = chartData.MeasureTypes[measure];
  switch (measureType) {
    case 5: // StepLine
      return "left";
  }

  return false;
}

function getHideSerieMarker(chartData, measure) {
  var measureType = chartData.MeasureTypes[measure];
  switch (measureType) {
    case 0: // Point
      // You can't hide the markers on a point chart or you don't have a chart
      return false;
    default:
      return true;
  }
}

function getSerieMarker(chartData, measure) {
  var hideSerieMarker = getHideSerieMarker(chartData, measure);
  return {
    // This must be true, otherwise the screenreader cannot read the points
    // and we would need to find an alternative way to provide the information.
    enabled: true,
    states: {
      hover: {
        enabled: true,
        radius: HOVER_MARKER_RADIUS,
      },
    },
    // We cannot use the fill color to hide the marker because
    // the marker should be shown on hover, and if we override
    // the fill color in the normal state, we cannot set it back
    // to the "line color" in the hover state.
    // So instead, we manipulate the radius to hide the marker.
    radius: hideSerieMarker ? HIDDEN_MARKER_RADIUS : DEFAULT_MARKER_RADIUS,
  };
}

// Get the inner size of a serie.
// Only used for doughnut charts.
function getSerieInnerSize(chartData, measure) {
  var measureType = chartData.MeasureTypes[measure];
  switch (measureType) {
    case 18: // Doughnut
      return useModena365Theme() ? "65%" : "40%";
  }

  return 0;
}

// Get the polar type of the first serie that is using polar.
function getPolarSeriesType(chartData) {
  for (var i = 0; i < chartData.Measures.length; i++) {
    var polar = getPolarSerieType(chartData, chartData.Measures[i]);
    if (polar) {
      return polar;
    }
  }

  return false;
}

// Get the polar type of a single serie.
// Only used by radar charts.
function getPolarSerieType(chartData, measure) {
  var measureType = chartData.MeasureTypes[measure];
  switch (measureType) {
    case 25: // Radar
      return true;
  }

  return false;
}

// Get the x-axis type. For data-time data the x-axis is set as
// datetime. For all other types it is set to category.
function getXAxisType(chartData) {
  if (chartData.XDimensionColumn.DataType.indexOf("System.DateTime") == 0) {
    return "datetime";
  }

  return "category";
}

// Get the minimum tick interval of the x-axis.
// Only used by datetime x-axis chart types.
function getXAxisMinTickInterval(xAxisType) {
  if (xAxisType == "datetime") {
    return 24 * 3600 * 1000; // one day
  }

  return null;
}

// Get the minimum value of the y-axis.
function getYAxisMin(chartData) {
  if (!isNaN(chartData.YAxisMinimum)) {
    return chartData.YAxisMinimum;
  }

  return null;
}

// Get the maximum value of the y-axis.
function getYAxisMax(chartData) {
  if (!isNaN(chartData.YAxisMaximum)) {
    return chartData.YAxisMaximum;
  }

  return null;
}

// Gets the maximum number of label lines on the x-axis.
function getXAxisLabelsMaxStaggerLines(height) {
  if (height < 260) {
    return 1;
  }

  if (height < 320) {
    return 2;
  }

  if (height < 380) {
    return 3;
  }

  return 4;
}

// Updates the x-axis labels settings that are dependent
// on the size of the chart.
function updateXAxisLabels(width, height) {
  var staggerLines = getXAxisLabelsMaxStaggerLines(height);

  var xAxisLabelsMaxStaggerLines = staggerLines > 1 ? staggerLines : null;
  var xAxisStaggerLines = staggerLines <= 1 ? staggerLines : null;

  // When updating the x-axis the labels get cleared, so we
  // must get a copy of the label before updating the x-axis
  var names = chart.xAxis[0].names;

  chart.xAxis[0].update(
    {
      labels: {
        staggerLines: xAxisStaggerLines,
        maxStaggerLines: xAxisLabelsMaxStaggerLines,
        overflow: "justify",
      },
    },
    false
  );

  // And now we can restore the labels on the x-axis
  chart.xAxis[0].names = names;
}

// Updates the legend settings that are dependent
// on the size of the chart.
function updateLegend(width, height) {
  var enableLegend = getEnableLegend(width, height);
  if (chart.options.legend["enabled"] != enableLegend) {
    chart.options.legend["enabled"] = enableLegend;
    chart.legend["enabled"] = enableLegend;
    chart.legend["display"] = enableLegend;

    var keyboardOrder = getKeyboardOrder(
      enableLegend,
      chart.legend.verticalAlign
    );
    chart.accessibility.keyboardNavigation["order"] = keyboardOrder;
    chart.options.accessibility.keyboardNavigation["order"] = keyboardOrder;

    for (var i = 0; i < chart.series.length; i++) {
      chart.series[i].update(
        {
          showInLegend: enableLegend,
        },
        false
      );

      // On pie charts we also need to disable the
      // data labels when showing the legend
      if (chart.series[i].type == "pie") {
        chart.series[i].update(
          {
            dataLabels: {
              enabled: !enableLegend,
            },
          },
          false
        );
      }
    }
  }

  // Highcharts does not recreate the legend accessibility proxies when enabled changes, so force it
  chart.options.legend.accessibility.enabled = enableLegend;
  chart.accessibility.components.legend.recreateProxies();
  chart.accessibility.components.legend.updateLegendTitle();
}

// Determine whether the chart contains a pie.
function chartContainsPie() {
  for (var i = 0; i < chart.series.length; i++) {
    if (chart.series[i].type == "pie") {
      return true;
    }
  }

  return false;
}

// Determine whether the chart data contains a pie.
function chartDataContainsPie(chartData) {
  for (var i = 0; i < chartData.Measures.length; i++) {
    if (getSerieType(chartData, chartData.Measures[i]) == "pie") {
      return true;
    }
  }

  return false;
}

// Determine whether the chart data contains an empty pie, i.e.
// a pie chart where all the values are zero.
function chartDataContainsEmptyPie(chartData) {
  var xAxisType = getXAxisType(chartData);

  for (var i = 0; i < chartData.Measures.length; i++) {
    var chartType = getSerieType(chartData, chartData.Measures[i]);

    if (chartType == "pie") {
      var data = getSerieData(chartData, chartData.Measures[i], xAxisType);

      for (var j = 0; j < data.length; j++) {
        var value = data[j].y;
        if (value != 0) {
          return false;
        }
      }

      return true;
    }
  }

  return false;
}

// Get whether the legend should be enabled.
function getEnableLegend(width, height) {
  return (
    getSeriesEnableLegend(width, height) || getPieEnableLegend(width, height)
  );
}

// Get whether the legend should be enabled for series.
function getSeriesEnableLegend(width, height) {
  // There is only one serie - no legend needed
  if (chart.series.length <= 1) {
    return false;
  }

  // If we have little height and tooltips are
  // enabled then hide the legend
  return height > 200 || !getToolTipEnabled();
}

// Gets whether the legend should be enabled on pie.
function getPieEnableLegend(width, height) {
  if (!chartContainsPie()) {
    return false;
  }

  // Use legend on pie if there is not room for data labels on the pie
  return width < 480 || (4 / 3) * height > width /*portrait*/;
}

// Gets the horizontal alignment of the legend.
function getHorizontalAlignmentLegend(chartData) {
  // Setting the horizontal alignment property when creating the chart is broken in
  // Highcharts 4.0.1, so instead we are using a CSS style for fixing the alignment.
  if (
    useModena365Theme() &&
    getVerticalAlignmentLegend(chartData) !== "bottom"
  ) {
    document.body.classList.add("left-align-legend");
  } else {
    document.body.classList.remove("left-align-legend");
  }

  return "center";
}

// Gets the vertical alignment of the legend.
function getVerticalAlignmentLegend(chartData) {
  // Show legend at the bottom for pie chart on the phone
  if (
    chartDataContainsPie(chartData) &&
    Microsoft.Dynamics.NAV.GetEnvironment().DeviceCategory == 2
  ) {
    return "bottom";
  }

  return "top";
}

function getKeyboardOrder(legendEnabled, verticalAlignmentLegend) {
  if (!legendEnabled) {
    return ["series"];
  }

  return verticalAlignmentLegend === "top"
    ? ["legend", "series"]
    : ["series", "legend"];
}

// Event handler called when the size of the chart is changed.
function onChartSizeChanged(width, height) {
  if (chart == null || height <= 0 || width <= 0) {
    return;
  }

  // Does the chart already have the requested size?
  var c = chart.xAxis[0].chart;
  if (c != null && c.chartHeight == height && c.chartHeight == height) {
    return;
  }

  onSizeChanged(width, height);
}

function onSizeChanged(width, height) {
  updateXAxisLabels(width, height);
  updateLegend(width, height);

  // Now make the chart recalculate the sizes
  // used for legend and chart. Setting the size
  // also triggers a redraw of the chart.
  chart.setSize();
}

// Event handler called when a point in the chart is clicked.
function onPointClick() {
  var xValueString;

  // use "this" instead of the received event object because the event object has
  // a different structure based on whether the event was activated by mouse or
  // keyboard. "this" is the same object regardless of activation method.
  var point = this;

  if (typeof point.name != "undefined") {
    xValueString = point.name;
  } else {
    // It is a date - we need to return the number of days since 31 Dec 1899
    // as the GetDateString function in Table 485 Business Chart Buffer
    // expects this.
    var timezone = new Date().getTimezoneOffset();
    var daysSince1970 = (point.x / (60 * 1000) - timezone) / (60 * 24);
    var daysSince1900 = daysSince1970 + 25569;
    xValueString = Math.round(daysSince1900 * 10) / 10;
  }

  raiseDataPointClicked({
    Measures: [point.series.name],
    XValueString: xValueString,
    YValues: [point.y],
  });
}

function isNaN(number) {
  return number == "NaN";
}

function getMessageClassName() {
  return "addInMessage" + getClassNameSuffix();
}

function getClassNameSuffix() {
  switch (Microsoft.Dynamics.NAV.GetEnvironment().DeviceCategory) {
    case 0:
    default:
      return "-desktop";
    case 1:
      return "-tablet";
    case 2:
      return "-phone";
  }
}

function useModena365Theme() {
  return document.body.classList.contains("theme-m365");
}

// SIG // Begin signature block
// SIG // MIInRAYJKoZIhvcNAQcCoIInNTCCJzECAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // 39Cs1WVIAASLyT1drvuMgtM9p4FZRMFblskax13SJbCg
// SIG // ggy6MIIF9TCCA92gAwIBAgITMwAAAh1NGchO1w9XSAAA
// SIG // AAACHTANBgkqhkiG9w0BAQsFADBXMQswCQYDVQQGEwJV
// SIG // UzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5n
// SIG // IFBDQSAyMDI0MB4XDTI2MDQxNjE4NTk0M1oXDTI3MDQx
// SIG // NTE4NTk0M1owdDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
// SIG // Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
// SIG // BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEeMBwG
// SIG // A1UEAxMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMIIBIjAN
// SIG // BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0L3sF8cf
// SIG // YGWRQumLNVgWsvASfJBgOCUJx+QjGn6jgEpU6SvR/KOW
// SIG // V017dHGlUEzTFD7eOOcF2A/nRbWilk8A59SOdqFEqwvb
// SIG // yYp9RrKrfs8iiS+Q4N3kF20DUetQ5jMttBi0yDt0hXnf
// SIG // UX4v6KYYAixhSw0d69Crx48DG/42FktHHpVf+C89uy3w
// SIG // HpJvL/ROSF2nol2wFGGSitPdJ+AlZdyQbWzfvQ7SPUjb
// SIG // v8o76M1udv7u0V/07aWvyg5abqJGfmXG75rXfbq/YBS7
// SIG // 2c4eNaPTLBP3JULXWhVhr7qOibmv57aYJHstxOf7wRXv
// SIG // jCTxuqYXZ7qOq+e2bnQrnYiNWwIDAQABo4IBmzCCAZcw
// SIG // DgYDVR0PAQH/BAQDAgeAMB8GA1UdJQQYMBYGCisGAQQB
// SIG // gjdMCAEGCCsGAQUFBwMDMB0GA1UdDgQWBBR+kLjMKnDx
// SIG // tIUJUOnOYwrU0y61XjBFBgNVHREEPjA8pDowODEeMBwG
// SIG // A1UECxMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMRYwFAYD
// SIG // VQQFEw0yMzAwMTIrNTA3NTU5MB8GA1UdIwQYMBaAFH9Z
// SIG // P1Qh2q1P7wXl5qPXLQaUEggxMGAGA1UdHwRZMFcwVaBT
// SIG // oFGGT2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
// SIG // cHMvY3JsL01pY3Jvc29mdCUyMENvZGUlMjBTaWduaW5n
// SIG // JTIwUENBJTIwMjAyNC5jcmwwbQYIKwYBBQUHAQEEYTBf
// SIG // MF0GCCsGAQUFBzAChlFodHRwOi8vd3d3Lm1pY3Jvc29m
// SIG // dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMENv
// SIG // ZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyNC5jcnQwDAYD
// SIG // VR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEASk22
// SIG // Do88Exvw1xms/bOvn0Hmk7Q3BZjGPuVMlRQso+z7/uYt
// SIG // +6n1/JUi/7QSH2EH1rDLgUJX2bqyQ+q+B1Sdgnh/tX4I
// SIG // qvHXB3VSqGd0mtql6F93KvYkvHFW9Oge/uf1yeyNDsRx
// SIG // /Xw7Lyd098OVf2bQCBZi65fj9ArRvvdrs0bJ9J023RYz
// SIG // pCzC1jywFN0x6ISkZUhDIBSaT5JuZ+VAGd+cV+hVgqwy
// SIG // 7Eim+eeW04n8GvJiQcHZaH9G5n2InR/ncWdRXQ8by5zZ
// SIG // fc3irAOJHo2miKqiD4LocALYuUJewZUzaCTcMQrwZqlt
// SIG // jEC5wpGDf1VVLEd1dsf63Ezc6AX/2f0qUTr3WgNmTjnd
// SIG // boqFybd7XS0O7x6aqYm9Cn1q/xVl1tdKt/FcXwp0UAas
// SIG // 20rs7Ue5xDLs1+wpPgf12jw13daoe9vkGMgdGdlc1pjv
// SIG // c7J2/VKv3cLvCxnkKp8ruu0gxgAr514otn2/flEuPdlU
// SIG // 510pxSsqsIM1MhTLWStf7B2E7+mxuE7UFMoEMUzfmVfm
// SIG // iSJSjtjKme2yqwJzs0vZujYKE3VjqtdW0zmcCpSBFfxI
// SIG // VfUlpA5naUf4Tz09r+kxI+BfD0/8x40XsyFOXPwxpbf1
// SIG // YWP6StF5CbRMjJpktQTLY1P66gWVTCJt3Z8ULP0wQcq/
// SIG // gn/Gda+2on0FUPlkqs4wgga9MIIEpaADAgECAhMzAAAA
// SIG // OTu2Nxm/Bh1nAAAAAAA5MA0GCSqGSIb3DQEBDAUAMIGI
// SIG // MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
// SIG // bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
// SIG // cm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNy
// SIG // b3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkg
// SIG // MjAxMTAeFw0yNDA4MDgyMDU0MThaFw0zNjAzMjIyMjEz
// SIG // MDRaMFcxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNy
// SIG // b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jv
// SIG // c29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMjQwggIiMA0G
// SIG // CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDYAZwe4zjH
// SIG // qpUWBzWtuub+CGPXx/EyoXph3zyDXtYKS2ld3YYN9uFs
// SIG // B9Oi3B26Z7AbpAgzYra8qNHbUvxFuiP8hC/2y0mPISqW
// SIG // 30LlrrAT6/ams2HA8Qlv6p42+SbCNbPGzToN21QE70FS
// SIG // +LXH9N2k8nLM/EHgnTNJf8h0TmyfUKmszNa+lTxDieyy
// SIG // /rhBG+98OkArobPPWtbr9c3qzmDJ7J3kUcAm6cltdSHI
// SIG // IFNHESgw6taY1ScyGyBevqIl120XjrIHiPM7tRckHytH
// SIG // 1ZGsmvEplR0P7Tn9t5meFvZNEYttkFvad1IEguTlA5LS
// SIG // scXAphi+rVy3zhklhyCFeGK0yU0+jzbcuURKIxybmRwK
// SIG // 5BfVZx0xEVqE4wM3yN5D/uW+GpVHYYAGe7bTrtW1Z13x
// SIG // 2qj2Jdqz7NtI4tNyzlVrIf62nYBNe3rOYS/repVdHlR6
// SIG // 1YbLLETlibs9jFzAre4sO5RTxvS1yho7JqJ59oKLRnRy
// SIG // LhIOSZyTCVZosXeS0ZZJoGEWSs4cUgsMqBiKtD4WgO2P
// SIG // lT3LeaQh5Io3CCA5tJ5ZCvtCsnqaJXKhptE/xmEETIRy
// SIG // ZRjjplUKKd+sFFVGJJVMvvrw1nhIBKOLO4cTepiG39jE
// SIG // iEP4iHzGYCcQuvaLpDFFwqzgt0pBP8SJIKX5dtjDNYrZ
// SIG // Gd+ZzV5DKJVNZQIDAQABo4IBTjCCAUowDgYDVR0PAQH/
// SIG // BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQW
// SIG // BBR/WT9UIdqtT+8F5eaj1y0GlBIIMTAZBgkrBgEEAYI3
// SIG // FAIEDB4KAFMAdQBiAEMAQTAPBgNVHRMBAf8EBTADAQH/
// SIG // MB8GA1UdIwQYMBaAFHItOgIxkEO5FAVO4eqnxzHRI4k0
// SIG // MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwubWlj
// SIG // cm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jv
// SIG // b0NlckF1dDIwMTFfMjAxMV8wM18yMi5jcmwwXgYIKwYB
// SIG // BQUHAQEEUjBQME4GCCsGAQUFBzAChkJodHRwOi8vd3d3
// SIG // Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0Nl
// SIG // ckF1dDIwMTFfMjAxMV8wM18yMi5jcnQwDQYJKoZIhvcN
// SIG // AQEMBQADggIBABSUHzgoT+6J5+nyyDCq0pTdVmCsAxYA
// SIG // HXcpjlDtxazPHewf1v4kOg8V7A5+w+VuMDMGHi8rLXBK
// SIG // n5I8+DVEUYGs8jLuckc0IeC6owOLUrU3CYdaKRMaO55+
// SIG // T7jwWJ27tPkx0rlR03tFU0z1YYpcv6Yhaw6N2sUPT+Av
// SIG // jpecnrftoE33pCAkucUvnGH0iL4J9CZLFQVTGFSOUBbv
// SIG // 6oZy4bBBRFMxvH779IY4JDvpZKVfbcuhpDeL3Z3e8muk
// SIG // Omkfct+GojNapsWsQYujlJ8jZen5Lrp/3YkxZ2Ay06aT
// SIG // pK/5oOVknwog1TDQsbY+MDyguTph5tQ0CLfzDaJG2x91
// SIG // BrBT9UG87C6HLkqiwrx9PSKN3wz05rHEfWO+RuKl+0U1
// SIG // /AHQT6NCOjhKI39/c7hWbdKjh5uuWFkBOvXGTNrnhNTA
// SIG // dOXTTYByvYExO8yryv34PAdqo1vPDE/1heVebr2Rramv
// SIG // RUi9kWswKwPqwz7n+iRmM+B6YDGRweEurM1kimAb9FYr
// SIG // As38YHlPnarl1vW3dGrmJTgefAz3DmCnXN0nveIPsS+K
// SIG // XBIWweeCToAJMGE7v/XS3h9qQ6niWQAAVQ1kUAml3zuS
// SIG // 4MisCgi2F6YoK2WAo1EgXK/lXvDxVjIVU0JdL+KvCfwF
// SIG // JkDeVuJ9dNXGNi+AOxk0BtYd9hxwL30BElj9MYIZ4jCC
// SIG // Gd4CAQEwbjBXMQswCQYDVQQGEwJVUzEeMBwGA1UEChMV
// SIG // TWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9N
// SIG // aWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDI0AhMz
// SIG // AAACHU0ZyE7XD1dIAAAAAAIdMA0GCWCGSAFlAwQCAQUA
// SIG // oIGuMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
// SIG // CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
// SIG // SIb3DQEJBDEiBCBaCH/r1N08OfZuxScA7vWjgnr/eWi7
// SIG // zOd4g1u0MoZ1hTBCBgorBgEEAYI3AgEMMTQwMqAUgBIA
// SIG // TQBpAGMAcgBvAHMAbwBmAHShGoAYaHR0cDovL3d3dy5t
// SIG // aWNyb3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIIBAH7K
// SIG // K4XdZ7lDVZJJ5vGJo3ofnRGM+XkF20OYKh8GgeJV9aOI
// SIG // w3+3rTXmzD67v8u3BM98GczhB0jtb+y4MBhNDbXDCouw
// SIG // TVSLU4Wrew3PS0cdp/SdO0P14T6qGtxJ5t6bCzWYL+yg
// SIG // WuzhQP6Y+LS5XOpKHp13CpXUgI3GFL+M/rNpv8oThJ9g
// SIG // o+qXOiOgF48i2daw3GmCvqN+Iiypg9DY1+GYZ9YpwM2i
// SIG // rHgncpG6JaxtofIF/N4vFLUkpWlxwr4pmq0Xcwpm4JF2
// SIG // iuzUZxX8fxMyITbvybblzKLeU7VHqlCplK69GUdKBvnk
// SIG // eZfmF8XHRpqH9GbJyUOk2UnZV/HKX/+hgheUMIIXkAYK
// SIG // KwYBBAGCNwMDATGCF4Awghd8BgkqhkiG9w0BBwKgghdt
// SIG // MIIXaQIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBUgYLKoZI
// SIG // hvcNAQkQAQSgggFBBIIBPTCCATkCAQEGCisGAQQBhFkK
// SIG // AwEwMTANBglghkgBZQMEAgEFAAQg7UI0eIkFyFAi0J3F
// SIG // wkkI/PA4Qbgerx4fbzKcpQADmeECBmnn1MYRKRgTMjAy
// SIG // NjA1MDExNzA3NDUuOTA0WjAEgAIB9KCB0aSBzjCByzEL
// SIG // MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
// SIG // EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
// SIG // c29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9z
// SIG // b2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMe
// SIG // blNoaWVsZCBUU1MgRVNOOjk2MDAtMDVFMC1EOTQ3MSUw
// SIG // IwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
// SIG // aWNloIIR6jCCByAwggUIoAMCAQICEzMAAAImNbQ+Z0OT
// SIG // 9h8AAQAAAiYwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UE
// SIG // BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
// SIG // BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
// SIG // b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
// SIG // bWUtU3RhbXAgUENBIDIwMTAwHhcNMjYwMjE5MTk0MDAy
// SIG // WhcNMjcwNTE3MTk0MDAyWjCByzELMAkGA1UEBhMCVVMx
// SIG // EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
// SIG // ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
// SIG // dGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
// SIG // T3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
// SIG // RVNOOjk2MDAtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNy
// SIG // b3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkq
// SIG // hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAv/8PmWSC+URR
// SIG // aVSPA92crjbvCM3ABDg99Di2I4d9+6143KyJTks6SXOG
// SIG // XlMRMpYusehes5uDUfHWz2/XYg6f4TlMx1hsYgNWd0Vy
// SIG // gW/+Bf6I8rzeN0hBlqkn1XNyNwZbGE9+XnFQCfZFX/dG
// SIG // Dr9vbRYyQQWZGL60/w8MMkS7HDsj+Kfvf5ciYw/lC7N2
// SIG // FwYVa32fjG0AfgWCi6kbwSm4/8EfWpDazMUCDaBmg+Y2
// SIG // Tvzf50rJhtj9c7/3L+IEqDAZ1nkCAZI3diOcNQ3l7qad
// SIG // r0ojZkebANmZASt8okFmib0cTg5ZH4sh5PTJJP062E45
// SIG // ozwm4XvrqoRzUcvFJWzr1rAqtLUbVMpB79/Q4KgHyTax
// SIG // PDkrfN+awcw6a63AIcJoH4aFYuACnqsIpGNJ1GuPCtEM
// SIG // vNF0+H4hANxMRGTWkRaPTavxsG34KiqhpnPcYSrkRXI7
// SIG // bmuCh2b5wL6VoBBUjgpKL17PwXC55BBzPcWfIlGoOQso
// SIG // Tal2GBP89KXF3WGjSJEOvBFprry5u4PaKH1drzpuRlTa
// SIG // IIZ5Fhupxj6PycBIJgPaEktBH7xUTFjwP4KUrxd7IQKy
// SIG // h52hKVUkotwzW8ormIhLPSqNCJGXPMShXkEWqhkcawft
// SIG // q/+wd1/NU6bPfSoRcIPsA/O6HdthdjFINce7cLd4GlZx
// SIG // ZNCGSMFDwhsCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBRd
// SIG // 4Z/X2CTdmP2fS1WwTyMQM1x7EDAfBgNVHSMEGDAWgBSf
// SIG // pxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSg
// SIG // UqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
// SIG // b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIw
// SIG // UENBJTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBe
// SIG // MFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
// SIG // dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
// SIG // bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNV
// SIG // HRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
// SIG // MA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOC
// SIG // AgEANlMdLa/bGAo7KtBUcolacdeTrqzV7+kJO4l/gK1T
// SIG // 5c98OLao3EzZtXbd7U7mtsCTKSYTx/J+1F4Zk/fHeQ7u
// SIG // OC5eGnZ7HuEkH1YN0C+mkZFx5yVJ/MvYn7Qfz8ttp/cZ
// SIG // 8DxX490JQzkoC7h5Xrve1NIh9mWpbmGm1lyYoXYmKSvH
// SIG // DxxZamTgIqLdPhg/HT/kTLr6cbfxdi5mHpaaGcK4ohTl
// SIG // JpcRFFe8SR8mWZQ6rrJHsrqtNQ07/dTeKjPHHzz4Zf9q
// SIG // XOB3jH/53dh6LonyWw0BTXeFj4S859Est7tWYd/kt7Y0
// SIG // HajfncsOtEWlfkVwqDi4BWdzAIPxqA5fn72+Ycv9Wu9X
// SIG // LV/MBGndT3+nXn9qan5d8BXPvoZBfA1102aHyTeGFWjd
// SIG // yJ8GwBkAw5DSuJannAoscZkisInT8pxnhOTrbzaCtaZC
// SIG // 7Jv4vBdUYxnM2f5EhdlQ5KhvOuokPo1WxjkOg7t3sshX
// SIG // BSmaAyeAeZhAEvWk9kiqpZS3smzm6B+q+u7IkeQf9h57
// SIG // u/imLmGctARGnbQOp4BuHJ0kfSbK5IYbCpm9dbo6sICc
// SIG // jcfdjLKBhsDYDdWiNECA/ArIwhcKX5jM5QOOMRymL94Z
// SIG // o8XqgUuLlOa0HogJ1YKSXmlRipv5czw7Z6aRlfu14Uae
// SIG // W9WcU/2e18XPiOx+/4wrUA2aGmUwggdxMIIFWaADAgEC
// SIG // AhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEB
// SIG // CwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
// SIG // aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
// SIG // ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQD
// SIG // EylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRo
// SIG // b3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5
// SIG // MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
// SIG // EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
// SIG // HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
// SIG // BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
// SIG // MDEwMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKC
// SIG // AgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51
// SIG // yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64
// SIG // NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1
// SIG // hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmv
// SIG // Haus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoP
// SIG // z130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1w
// SIG // jjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3tpK56
// SIG // KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7
// SIG // vnGpF1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ1v2l
// SIG // IH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHovwUD
// SIG // o9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhz
// SIG // PUNOwTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtco
// SIG // dgLiMxhy16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGU
// SIG // lNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsl
// SIG // uq9QBXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W2
// SIG // 9R6HXtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZ
// SIG // MBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUC
// SIG // BBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQW
// SIG // BBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBT
// SIG // MFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNo
// SIG // dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0Rv
// SIG // Y3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYB
// SIG // BQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEw
// SIG // CwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYD
// SIG // VR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYD
// SIG // VR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3Nv
// SIG // ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2Vy
// SIG // QXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4w
// SIG // TDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3Nv
// SIG // ZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAx
// SIG // MC0wNi0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1V
// SIG // ffwqreEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9
// SIG // MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulm
// SIG // ZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pv
// SIG // vinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbz
// SIG // aN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3
// SIG // +SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsId
// SIG // w2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5m
// SIG // O0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSwethQ
// SIG // /gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9
// SIG // swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu
// SIG // +yFUa2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyh
// SIG // YWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFR
// SIG // hLy/AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0
// SIG // +CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAx
// SIG // M328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQ
// SIG // wXEGahC0HVUzWLOhcGbyoYIDTTCCAjUCAQEwgfmhgdGk
// SIG // gc4wgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
// SIG // aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
// SIG // ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsT
// SIG // HE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAl
// SIG // BgNVBAsTHm5TaGllbGQgVFNTIEVTTjo5NjAwLTA1RTAt
// SIG // RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
// SIG // bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAov3zMRbZ
// SIG // Kq+1zF3bEcllNJUih2eggYMwgYCkfjB8MQswCQYDVQQG
// SIG // EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
// SIG // BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
// SIG // cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
// SIG // ZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIF
// SIG // AO2e1/EwIhgPMjAyNjA1MDEwNzQyNDFaGA8yMDI2MDUw
// SIG // MjA3NDI0MVowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA
// SIG // 7Z7X8QIBADAHAgEAAgIGHTAHAgEAAgISrzAKAgUA7aAp
// SIG // cQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZ
// SIG // CgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqG
// SIG // SIb3DQEBCwUAA4IBAQCrlo1RSKGOGpzII3VhbuY5+/pA
// SIG // QzgDgPm9rv11u6mrIW4irGhFtVVGU/vsGXCtHhyu3a/Y
// SIG // dZLOO6iFs+zz+8He/Zf4kher9FV1b3OsvvEwSF3CMnEa
// SIG // YQzH8sjdvEHVUBMWpDcWSYzYSG0qPGQPdZ7EPE+nP0G9
// SIG // aqRfNUFp97DaW6G4wC8y9Af4IAqELd6yLZbbwga6qUJv
// SIG // 7KuoVfeACDYqLc9UhlCRbDUXO2PJsw04xWSzwOTSwiwv
// SIG // iMESRpC6r3dyObA1n6rZGVzN6pChpCUPyKyGHwPMXw3q
// SIG // hZPfYfLo2GbDNcoTxl2csSzCZ609A2t2hGR3Y/V71F60
// SIG // 7PTr/3HmMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMC
// SIG // VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
// SIG // B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
// SIG // b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
// SIG // U3RhbXAgUENBIDIwMTACEzMAAAImNbQ+Z0OT9h8AAQAA
// SIG // AiYwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJ
// SIG // AzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQg
// SIG // Q6EkqBzOX3SGdM7TB50yZO9bQ5DBWw1P+0zoAUwOYAAw
// SIG // gfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDMMlxh
// SIG // Z0zbGUQa7OhjfwW1dKJGjT91QWKixY1LBZ24KjCBmDCB
// SIG // gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
// SIG // aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
// SIG // ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
// SIG // HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
// SIG // AAACJjW0PmdDk/YfAAEAAAImMCIEIOUhpGj9SFnXLrZa
// SIG // Rb8VdB4JaekeYRRatLQmnZSlikgWMA0GCSqGSIb3DQEB
// SIG // CwUABIICABr0udatEKujI3XHg0Db2DYVva0ZOcc+hC6a
// SIG // 7Qx1lJJEKJU7RMOjZj4KMkVovS7FvarDNwSzfO1EqA3p
// SIG // XqZ8BZSNAwdU031RWJtPgbf4YwJt2+NxBZZerOdevmBn
// SIG // oojTKGlmJCj6cY1sX7+8X6gqwgDnqBJcbLd+rQ+b25ZK
// SIG // DxLVme3MTLnkLK8kI42r5wjyNuhGhPjSqP3MRYaREEpC
// SIG // Fu/GFSrWkShhyXF4QIkOGXik2E/+PO4Yt/4+49fpYX/H
// SIG // AyrtXkGdkksuMUWuZB9XpXt0bu0UYtT5hic1w1VbJI1H
// SIG // 71VGhm0/XCwpGbdF340BkmIhPQGDL+6x3tERWOHae2xT
// SIG // k8Rjs4gBN5L7BNaaMyh9k/JWV8MlfJHfMZIaAh5DclQk
// SIG // E30GOn5ognf6SXKxuFPlGPe7HBn9MJmC/amOv/Kr6lsf
// SIG // UoXHMVQCSYJ61BaFGUf382OZFH1+o1aixCZZ7ewN+WL1
// SIG // SJjwdaL1ccMNNLPb8F5nPAExElZcY7ki4Edab6dNyG/L
// SIG // tIpqcADk/1IbztcsUJLYus7jzeK/4zq98+tDbPjx7MJY
// SIG // aE/SYBBON+Hn7XgM1fbVraVuGJxE/GT7A8XJGXjqWxw+
// SIG // ER+Yl2mIhWDTbNxkNC2K3dyaOL2qEDkIsWSvZcC+2CC2
// SIG // 9mxyQINmXSMkjN8zseZ56gmB0eSaHmp3
// SIG // End signature block
