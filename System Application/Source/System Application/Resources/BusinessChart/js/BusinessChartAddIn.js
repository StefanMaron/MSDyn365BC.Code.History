/*! Copyright (C) Microsoft Corporation. All rights reserved. */
"use strict";

var chart = null,
  stackIndex;

var TURBO_THRESHOLD = 5000;

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

  if (!validateDataPointCount(chartData)) {
    return false;
  }

  return true;
}

function validateDataPointCount(chartData) {
  if (chartData.DataTable.length > TURBO_THRESHOLD) {
    createMessage(chartData.Resources.TooManyDataPoints);
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
      turboThreshold: TURBO_THRESHOLD,
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
// SIG // MIInbAYJKoZIhvcNAQcCoIInXTCCJ1kCAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // 89fBCfcfyZBWR8mIPCYZJCyKhWM3bHA5GRstLzo+jI+g
// SIG // ggzJMIIGBDCCA+ygAwIBAgITMwAAAhz6zcWb6C9+xAAA
// SIG // AAACHDANBgkqhkiG9w0BAQsFADBXMQswCQYDVQQGEwJV
// SIG // UzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5n
// SIG // IFBDQSAyMDI0MB4XDTI2MDQxNjE4NTk0MVoXDTI3MDQx
// SIG // NTE4NTk0MVowdDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
// SIG // Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
// SIG // BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEeMBwG
// SIG // A1UEAxMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMIIBIjAN
// SIG // BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1bGX4Dip
// SIG // jN9Rz36FjqDRIsNEpQoiMVDAtCPTTFm7nCjsP3vZT6AK
// SIG // HoUFbukhuuVeBD862LJwZxTzaIuPx6DnY4c9apKxLeCO
// SIG // rRHMV1OqDnmPcxr3gv94gXroS2MTNzPz5HFKHmxfjXnZ
// SIG // 5vDpHUj6A7vIplYhz0Kv/AkFLtFkUeKxPnTEX66Van5j
// SIG // Ytqlgl/eE+DLHqYoxlZMBP/7SYNK8gImHR09+C0p5Rv0
// SIG // UgWZkERlmeYPI6pyo0T2q0qjH7dYL47lE1YLVjWX4HCx
// SIG // UiuVmtJsq6vDj3IExhrEYLp/rZ0kviMQ08VbADx9Ts7z
// SIG // 48KJoLgcoVHvznL1DdA+Vpqe8QIDAQABo4IBqjCCAaYw
// SIG // DgYDVR0PAQH/BAQDAgeAMB8GA1UdJQQYMBYGCisGAQQB
// SIG // gjdMCAEGCCsGAQUFBwMDMB0GA1UdDgQWBBTaB+2tmA4z
// SIG // ksKZKegx3JlEuyftMjBUBgNVHREETTBLpEkwRzEtMCsG
// SIG // A1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9u
// SIG // cyBMaW1pdGVkMRYwFAYDVQQFEw0yMzAwMTIrNTA3NTY5
// SIG // MB8GA1UdIwQYMBaAFH9ZP1Qh2q1P7wXl5qPXLQaUEggx
// SIG // MGAGA1UdHwRZMFcwVaBToFGGT2h0dHA6Ly93d3cubWlj
// SIG // cm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
// SIG // MENvZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyNC5jcmww
// SIG // bQYIKwYBBQUHAQEEYTBfMF0GCCsGAQUFBzAChlFodHRw
// SIG // Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRz
// SIG // L01pY3Jvc29mdCUyMENvZGUlMjBTaWduaW5nJTIwUENB
// SIG // JTIwMjAyNC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
// SIG // 9w0BAQsFAAOCAgEAFJxKoWkV3tE94SCY73UBKxJKwP+2
// SIG // wco5+reSAKzg5JEY85GMLSjHNsmI9qrmjay7rVsNmGXJ
// SIG // 4Cj8tW+9WMgyUE8uDQ0cGkofU8ObYa5NzZnD6wB4mub7
// SIG // XASdQoLSiu5kGyHENtnfzd/Nd2sggwxXsLtfo7GZl/q/
// SIG // 2kxKmjjOE1cVbUUpLgsvJwFyrgoTii4v8wOF7h/IhGKi
// SIG // LI9mKDWnksVZnhohEV6SnaN3Q5mItJDucNg/FUuHN/vY
// SIG // eoBJWAWgAIP3WBKwYNu6k9779M0QyYSbn7wjcpQPEu//
// SIG // vB+RPz1eXJ4Op2vVVf8PTld6rrjQ+s3RmthF9/BpaedB
// SIG // fQCEJN6dsV5nL6Kw3jOFye1JVmAYuoPNCdUkjkJyJwmB
// SIG // RJrH1DZ9/tQGkySkiS/N6rigK02nNqSobtGM88686Oh6
// SIG // 7EYkCs6Z0QW9f3TGuj94c++V2zEQXLTbBYWQtO1gpoxM
// SIG // XS4Nnh1ubldE2PA+fusKMyX+7xd/lh5GDzvOWfgQulOB
// SIG // ZDW2DcnGfXBOI9bV0Xcgwn5penNB1jx4zVQzm67/ZSrd
// SIG // 6lKhaV9/FQqlQsjTjtVHF30IlYycN9lNllCmY7f53iSh
// SIG // xAbJvZBbC7ls5EOd/qnGkmsrZrAp5NoDoJa5Q+Xd5Csr
// SIG // 7wMPq85tJU/Ct/D+jy8X2UB4buFvHVewL/DdmZgwgga9
// SIG // MIIEpaADAgECAhMzAAAAOTu2Nxm/Bh1nAAAAAAA5MA0G
// SIG // CSqGSIb3DQEBDAUAMIGIMQswCQYDVQQGEwJVUzETMBEG
// SIG // A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
// SIG // ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZp
// SIG // Y2F0ZSBBdXRob3JpdHkgMjAxMTAeFw0yNDA4MDgyMDU0
// SIG // MThaFw0zNjAzMjIyMjEzMDRaMFcxCzAJBgNVBAYTAlVT
// SIG // MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
// SIG // KDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcg
// SIG // UENBIDIwMjQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
// SIG // ggIKAoICAQDYAZwe4zjHqpUWBzWtuub+CGPXx/EyoXph
// SIG // 3zyDXtYKS2ld3YYN9uFsB9Oi3B26Z7AbpAgzYra8qNHb
// SIG // UvxFuiP8hC/2y0mPISqW30LlrrAT6/ams2HA8Qlv6p42
// SIG // +SbCNbPGzToN21QE70FS+LXH9N2k8nLM/EHgnTNJf8h0
// SIG // TmyfUKmszNa+lTxDieyy/rhBG+98OkArobPPWtbr9c3q
// SIG // zmDJ7J3kUcAm6cltdSHIIFNHESgw6taY1ScyGyBevqIl
// SIG // 120XjrIHiPM7tRckHytH1ZGsmvEplR0P7Tn9t5meFvZN
// SIG // EYttkFvad1IEguTlA5LSscXAphi+rVy3zhklhyCFeGK0
// SIG // yU0+jzbcuURKIxybmRwK5BfVZx0xEVqE4wM3yN5D/uW+
// SIG // GpVHYYAGe7bTrtW1Z13x2qj2Jdqz7NtI4tNyzlVrIf62
// SIG // nYBNe3rOYS/repVdHlR61YbLLETlibs9jFzAre4sO5RT
// SIG // xvS1yho7JqJ59oKLRnRyLhIOSZyTCVZosXeS0ZZJoGEW
// SIG // Ss4cUgsMqBiKtD4WgO2PlT3LeaQh5Io3CCA5tJ5ZCvtC
// SIG // snqaJXKhptE/xmEETIRyZRjjplUKKd+sFFVGJJVMvvrw
// SIG // 1nhIBKOLO4cTepiG39jEiEP4iHzGYCcQuvaLpDFFwqzg
// SIG // t0pBP8SJIKX5dtjDNYrZGd+ZzV5DKJVNZQIDAQABo4IB
// SIG // TjCCAUowDgYDVR0PAQH/BAQDAgGGMBAGCSsGAQQBgjcV
// SIG // AQQDAgEAMB0GA1UdDgQWBBR/WT9UIdqtT+8F5eaj1y0G
// SIG // lBIIMTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAP
// SIG // BgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHItOgIx
// SIG // kEO5FAVO4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuG
// SIG // SWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3Js
// SIG // L3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8w
// SIG // M18yMi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUF
// SIG // BzAChkJodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
// SIG // L2NlcnRzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
// SIG // Mi5jcnQwDQYJKoZIhvcNAQEMBQADggIBABSUHzgoT+6J
// SIG // 5+nyyDCq0pTdVmCsAxYAHXcpjlDtxazPHewf1v4kOg8V
// SIG // 7A5+w+VuMDMGHi8rLXBKn5I8+DVEUYGs8jLuckc0IeC6
// SIG // owOLUrU3CYdaKRMaO55+T7jwWJ27tPkx0rlR03tFU0z1
// SIG // YYpcv6Yhaw6N2sUPT+AvjpecnrftoE33pCAkucUvnGH0
// SIG // iL4J9CZLFQVTGFSOUBbv6oZy4bBBRFMxvH779IY4JDvp
// SIG // ZKVfbcuhpDeL3Z3e8mukOmkfct+GojNapsWsQYujlJ8j
// SIG // Zen5Lrp/3YkxZ2Ay06aTpK/5oOVknwog1TDQsbY+MDyg
// SIG // uTph5tQ0CLfzDaJG2x91BrBT9UG87C6HLkqiwrx9PSKN
// SIG // 3wz05rHEfWO+RuKl+0U1/AHQT6NCOjhKI39/c7hWbdKj
// SIG // h5uuWFkBOvXGTNrnhNTAdOXTTYByvYExO8yryv34PAdq
// SIG // o1vPDE/1heVebr2RramvRUi9kWswKwPqwz7n+iRmM+B6
// SIG // YDGRweEurM1kimAb9FYrAs38YHlPnarl1vW3dGrmJTge
// SIG // fAz3DmCnXN0nveIPsS+KXBIWweeCToAJMGE7v/XS3h9q
// SIG // Q6niWQAAVQ1kUAml3zuS4MisCgi2F6YoK2WAo1EgXK/l
// SIG // XvDxVjIVU0JdL+KvCfwFJkDeVuJ9dNXGNi+AOxk0BtYd
// SIG // 9hxwL30BElj9MYIZ+zCCGfcCAQEwbjBXMQswCQYDVQQG
// SIG // EwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
// SIG // aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWdu
// SIG // aW5nIFBDQSAyMDI0AhMzAAACHPrNxZvoL37EAAAAAAIc
// SIG // MA0GCWCGSAFlAwQCAQUAoIGuMBkGCSqGSIb3DQEJAzEM
// SIG // BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgor
// SIG // BgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCC5iyPMZVmW
// SIG // RKMG3Bq02ulzKAAOkSCc4IvpXLtOQiY4xjBCBgorBgEE
// SIG // AYI3AgEMMTQwMqAUgBIATQBpAGMAcgBvAHMAbwBmAHSh
// SIG // GoAYaHR0cDovL3d3dy5taWNyb3NvZnQuY29tMA0GCSqG
// SIG // SIb3DQEBAQUABIIBAALppDnYbCRRXeHAT4eg0qFD/4Wp
// SIG // lYCboWFD9G4iKjjGR6/R39hckAOOPbuL0k+uCrrYN311
// SIG // dvVlo8xLeE51IRIa7Ug7rGMkfLRISO83te4JtMZXYGx0
// SIG // 07/YM2q76Lr2IrfEZewQwXNtKIb7x27OdEwibAwWIOM4
// SIG // JmyDtOqX6b+RRQWEcf9BLHFCX9JVoulWTqJroLgCOhFo
// SIG // bObYYvVUre1McwW60RHz77gR6q3zb7dyWeRvpOJZcRyZ
// SIG // bEgAORXomgj7Asl40olmWq3jvRTLT/EYd40JAN8+VR0C
// SIG // TsIfSwLLn6LqN2cRmkLvqR9GCRMy8iEhBKNlv6yayMuc
// SIG // 4V4H96+hghetMIIXqQYKKwYBBAGCNwMDATGCF5kwgheV
// SIG // BgkqhkiG9w0BBwKggheGMIIXggIBAzEPMA0GCWCGSAFl
// SIG // AwQCAQUAMIIBWgYLKoZIhvcNAQkQAQSgggFJBIIBRTCC
// SIG // AUECAQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEF
// SIG // AAQgrM2XddMVlRtoXV8csp09VYoK0FUnev2nHZABlpdi
// SIG // /hUCBmqIbA0ZRxgTMjAyNjA5MTQyMDA2MDQuODIzWjAE
// SIG // gAIB9KCB2aSB1jCB0zELMAkGA1UEBhMCVVMxEzARBgNV
// SIG // BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
// SIG // HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEt
// SIG // MCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0
// SIG // aW9ucyBMaW1pdGVkMScwJQYDVQQLEx5uU2hpZWxkIFRT
// SIG // UyBFU046MzIxQS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1p
// SIG // Y3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghH7MIIH
// SIG // KDCCBRCgAwIBAgITMwAAAhqpoB0GoA9DqgABAAACGjAN
// SIG // BgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEG
// SIG // A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
// SIG // ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
// SIG // MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
// SIG // Q0EgMjAxMDAeFw0yNTA4MTQxODQ4MjhaFw0yNjExMTMx
// SIG // ODQ4MjhaMIHTMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
// SIG // V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
// SIG // A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYD
// SIG // VQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25z
// SIG // IExpbWl0ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
// SIG // TjozMjFBLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
// SIG // b2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZI
// SIG // hvcNAQEBBQADggIPADCCAgoCggIBAJmBAMEk8+/atld2
// SIG // Vs0ORL+0SoGnULTAcu/ld10PEdDS/EfZrqcXKiUPyj3m
// SIG // RiUxEfvUKv7exzkHwWw8untE3qbwRVf0WN8PizjzCp9F
// SIG // KIdv/CL3UmyfKgFkVaM9kvVayc2aQfP3+a0HERE4F/7f
// SIG // Deug9iZRF7+H2UAe183CTF69abobl2zrfUWBMjdUN2e2
// SIG // I0ZIXwbEXPkg/wvReIsGan0IKPNhhuMILiIYyVO/lzH6
// SIG // 7+L8QBTVYN5p9T6DFhmVoqPntePjxmD1SypWnftCIXRy
// SIG // uQID8lypKgIRGaWIWGFRCLRzjr6q8LpMVQCVzL1gNxmr
// SIG // VpEWZ991gyVbYIQlulzy4tXAyohhOVHF2UleDo0CFAfL
// SIG // 6di1DEV7neSOPRSAXBPZ09NM/APhHpKzzPjgJNO2g38G
// SIG // W3Zmeeo+7m+XzQy3/MiG/EMWfDK+EcFsv3Mwblea5FkE
// SIG // PprIyeQCrWGcSXZ2mXoVIFDQK1P7t+kh9XlyjEBkV6/8
// SIG // XihRiPL77+SZdZJ2fFKhEK/T8Q24rOzl6dlkjCuZSxnW
// SIG // FR/FaMJ2Bd7GzokZMeUORmhMk3oTkKdkn3W7CWZYNEl5
// SIG // h6YRp6Ftf4EP+T+gYEquDwFiGWgyY+gLyywnW1EYEeWq
// SIG // TUEHnds2FIFG4wAgP06JgPC5ewK679qGRolDuVXYuMcb
// SIG // QNwUU0E1AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQU8Ksi
// SIG // Cd0DKD2rA3BnRqL22mPCJTYwHwYDVR0jBBgwFoAUn6cV
// SIG // XQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
// SIG // UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
// SIG // cy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBD
// SIG // QSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBc
// SIG // BggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
// SIG // Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1l
// SIG // LVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0T
// SIG // AQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
// SIG // BgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIB
// SIG // ANWu9lhauwemyU91TidtZ506DyfTv6udW8NW4T30Muu7
// SIG // svn/MfGpIqczS9pOW+prcbj22RqQaqQSoLg8EJsVaV/H
// SIG // Bpmn3qN8Bq+GvGJOkstPbRIfzcMJbMquwUayTZ+mxjgf
// SIG // IhuDk8vqZjFIexXozT0YL4HqPzj8rZuDTazDIPfFFZa2
// SIG // cRjTmLIn6USRYOYxP2LupahWtZU5vXB7j2MVmtqBMAtL
// SIG // BALExW+vYiqTdLDtfcQWQq9IeQpVPT4KOnpIiW+0CaA8
// SIG // 6w6D0B8GzQPOwraO0y7qYY9JvZfyO9IC4xKud0h47lEc
// SIG // 8KZjcXZtfEIPq5ZGjAumNirpDnye6Akrvb3DRkDPop5f
// SIG // YLDYIq2esiZPVbFxLKE7aEe3zDVOj8urnyUBjE5qumQq
// SIG // tniBjl1jAW+/WRerYik2uKmpot1EtJk2ONSddvV5gIJV
// SIG // cvro0mZB7tpRyQ0R7OxY5yF2VVBOaZeslCJdt4xudH0U
// SIG // y0HErXcGPy7yVIBBwiM475S06i7eiVUeW3LOWjeA4dGD
// SIG // xveQfYgzGa6uK5YuUpxjVnr+Sy7A2NX26yurlaQ/qbL0
// SIG // i7DaYbdu0HB0bGHQDAC1zPhzbM9i2fMYjn8LeqzrFVl6
// SIG // Ih1fOv03jMuU2RVJe6gefSDaDEiYA0ZWnVV3k/X8Droq
// SIG // xSKKoIyhpN7ztmxC62DDdEFcMIIHcTCCBVmgAwIBAgIT
// SIG // MwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsF
// SIG // ADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
// SIG // bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
// SIG // FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMp
// SIG // TWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
// SIG // aXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMw
// SIG // MTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
// SIG // V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
// SIG // A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
// SIG // VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
// SIG // MDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
// SIG // AOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjK
// SIG // NVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZn
// SIG // hUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ
// SIG // 3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2r
// SIG // rPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxqD89d
// SIG // 9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4x
// SIG // yDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3
// SIG // rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75x
// SIG // qRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9
// SIG // fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PR
// SIG // c6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1D
// SIG // TsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC
// SIG // 4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTY
// SIG // uVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqv
// SIG // UAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUe
// SIG // h17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TAS
// SIG // BgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQW
// SIG // BBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQU
// SIG // n6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBR
// SIG // BgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0
// SIG // cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2Nz
// SIG // L1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUF
// SIG // BwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsG
// SIG // A1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1Ud
// SIG // IwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1Ud
// SIG // HwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0
// SIG // LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1
// SIG // dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEww
// SIG // SgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0
// SIG // LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAt
// SIG // MDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38
// SIG // Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEz
// SIG // tTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6
// SIG // U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74p
// SIG // y27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jf
// SIG // ZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kp
// SIG // icO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNh
// SIG // cy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtP
// SIG // u4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4K
// SIG // WN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMB
// SIG // V0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvsh
// SIG // VGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFs
// SIG // c/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8
// SIG // vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgk
// SIG // NWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9
// SIG // vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFx
// SIG // BmoQtB1VM1izoXBm8qGCA1YwggI+AgEBMIIBAaGB2aSB
// SIG // 1jCB0zELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
// SIG // bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
// SIG // FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMk
// SIG // TWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1p
// SIG // dGVkMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzIx
// SIG // QS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBU
// SIG // aW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMV
// SIG // APGK7rZiqUq7mwmgGLFOKbdRbfA2oIGDMIGApH4wfDEL
// SIG // MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
// SIG // EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
// SIG // c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
// SIG // b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcN
// SIG // AQELBQACBQDuUowDMCIYDzIwMjYwOTE0MTUwNjQzWhgP
// SIG // MjAyNjA5MTUxNTA2NDNaMHQwOgYKKwYBBAGEWQoEATEs
// SIG // MCowCgIFAO5SjAMCAQAwBwIBAAICDwcwBwIBAAICE1Qw
// SIG // CgIFAO5T3YMCAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYK
// SIG // KwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGG
// SIG // oDANBgkqhkiG9w0BAQsFAAOCAQEAk9xEtvzwWbwyzB5N
// SIG // wx/VlrvZaBKKGgETFVGuLxzKyQ6xTa7tcrwsEgtJULZm
// SIG // k6L2E6BMXU1+sj9ae4345qLW4qhejrMyMsMy/qNk4HRm
// SIG // 425gVx6athUpPnXkO5ZyHIwLnAqCfFfTLRKa0qn0K/jJ
// SIG // WKS+GhQR7/+2wHF3SmfkaydInK+aCsFHvbfpr7ER7n3l
// SIG // 0dD1RTJ3CZYD1AHBrsBudP+XRmhy+mUe+0E0msUEyeoL
// SIG // /ysdvw+j7lpP43cDtLuTkOL8CyB8uCspD9gZxVXvd8pk
// SIG // JecBCGWHxn+P1qKmkkkFqJqDpEkTfiXUHEJg3UCDRwuN
// SIG // 2u4yanKGr6na6qbBAjGCBA0wggQJAgEBMIGTMHwxCzAJ
// SIG // BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
// SIG // DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
// SIG // ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
// SIG // dCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAACGqmgHQag
// SIG // D0OqAAEAAAIaMA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkq
// SIG // hkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcN
// SIG // AQkEMSIEIK6p6/ftIsWWum4eH8xupVcZipGx3Uf6NVWR
// SIG // a8G1oLbRMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCB
// SIG // vQQgnXohx627aSnMAdtHaFVPPVhyDh/Eu8N+7mh3A5np
// SIG // ivswgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UE
// SIG // CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
// SIG // MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYw
// SIG // JAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
// SIG // MjAxMAITMwAAAhqpoB0GoA9DqgABAAACGjAiBCCL6Q7x
// SIG // p/Xa62ZW93OhTWbwkcDSW1vKA3Mk+NsZQWGjiDANBgkq
// SIG // hkiG9w0BAQsFAASCAgCHpQZ+vMZ/WZVOOkd3MmVWpbqR
// SIG // kOqUsWadD56cutZoC4ytZ+612cTz58tZvSJD5malwkkg
// SIG // 7iVpbTVcB/zHG75TzeiO60LlE2cUFk91kTJIsDZLp3NW
// SIG // aoGg6uOQzvXAANvZ2kWwjlukpyzrppgdbSLF+Utc0G+v
// SIG // b2ua3Hlj0bVHf+/MBYDHO8GpFfAw5G6qXUXcrJ9z/qrT
// SIG // lI3RQEHiGJpl+58M+lG5rR0lihQdZf2wG8d4Lu/SYA1Q
// SIG // Rf+47/oydV1dhPKI5jIW7LATWwacM7BrdAvr1TeJ1N4e
// SIG // hPM7VrJ53vKJWDiKl1+fiRlBPGS9QVh8aictEbJ4ll2/
// SIG // m5j2jVwBULS6ytI3dTz5HRDAtxTGurCmxqYBNT7JHcA7
// SIG // PTWBaTp4J9aZbycY4crSZ8VbDTBzgtGbn9V6KPGyUULy
// SIG // NkXGAVzRrtOwDzzabe3TIyRvZ8aPRTChyFZyUqDfUG12
// SIG // pj0IX76qY9/hpI+fxzWTlG7gHHHavLXVltxMKwKRnyYQ
// SIG // vNesaM8VqsQLRAut9KvXChzkHewV3JbP3kIQvcQY06XV
// SIG // LtoOeP0OBc+u7Rn9XQJ4JjPlmT72tDSsU0G1UIoIOXu2
// SIG // v6ehqOoDMYyaIBIa5+9QJoONh28/Xvh1MfsxyLYW/7OL
// SIG // WEaMfyLRdP6cCatoYgpHELaC+hZJbKvSrTpewWJ9mg==
// SIG // End signature block
