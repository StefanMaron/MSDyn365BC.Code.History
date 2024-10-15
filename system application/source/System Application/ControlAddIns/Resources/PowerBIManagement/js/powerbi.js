// powerbi-client v2.22.2
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory();
	else if(typeof define === 'function' && define.amd)
		define([], factory);
	else if(typeof exports === 'object')
		exports["powerbi-client"] = factory();
	else
		root["powerbi-client"] = factory();
})(this, () => {
return /******/ (() => { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ "./node_modules/http-post-message/dist/httpPostMessage.js":
/*!****************************************************************!*\
  !*** ./node_modules/http-post-message/dist/httpPostMessage.js ***!
  \****************************************************************/
/***/ (function(module) {

/*! http-post-message v0.2.3 | (c) 2016 Microsoft Corporation MIT */
(function webpackUniversalModuleDefinition(root, factory) {
	if(true)
		module.exports = factory();
	else {}
})(this, function() {
return /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __nested_webpack_require_626__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;
/******/
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __nested_webpack_require_626__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__nested_webpack_require_626__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__nested_webpack_require_626__.c = installedModules;
/******/
/******/ 	// __webpack_public_path__
/******/ 	__nested_webpack_require_626__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __nested_webpack_require_626__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports) {

	"use strict";
	var HttpPostMessage = (function () {
	    function HttpPostMessage(windowPostMessageProxy, defaultHeaders, defaultTargetWindow) {
	        if (defaultHeaders === void 0) { defaultHeaders = {}; }
	        this.defaultHeaders = defaultHeaders;
	        this.defaultTargetWindow = defaultTargetWindow;
	        this.windowPostMessageProxy = windowPostMessageProxy;
	    }
	    // TODO: See if it's possible to share tracking properties interface?
	    // The responsibility of knowing how to configure windowPostMessageProxy for http should
	    // live in this http class, but the configuration would need ITrackingProperties
	    // interface which lives in WindowPostMessageProxy. Use <any> type as workaround
	    HttpPostMessage.addTrackingProperties = function (message, trackingProperties) {
	        message.headers = message.headers || {};
	        if (trackingProperties && trackingProperties.id) {
	            message.headers.id = trackingProperties.id;
	        }
	        return message;
	    };
	    HttpPostMessage.getTrackingProperties = function (message) {
	        return {
	            id: message.headers && message.headers.id
	        };
	    };
	    HttpPostMessage.isErrorMessage = function (message) {
	        if (typeof (message && message.statusCode) !== 'number') {
	            return false;
	        }
	        return !(200 <= message.statusCode && message.statusCode < 300);
	    };
	    HttpPostMessage.prototype.get = function (url, headers, targetWindow) {
	        if (headers === void 0) { headers = {}; }
	        if (targetWindow === void 0) { targetWindow = this.defaultTargetWindow; }
	        return this.send({
	            method: "GET",
	            url: url,
	            headers: headers
	        }, targetWindow);
	    };
	    HttpPostMessage.prototype.post = function (url, body, headers, targetWindow) {
	        if (headers === void 0) { headers = {}; }
	        if (targetWindow === void 0) { targetWindow = this.defaultTargetWindow; }
	        return this.send({
	            method: "POST",
	            url: url,
	            headers: headers,
	            body: body
	        }, targetWindow);
	    };
	    HttpPostMessage.prototype.put = function (url, body, headers, targetWindow) {
	        if (headers === void 0) { headers = {}; }
	        if (targetWindow === void 0) { targetWindow = this.defaultTargetWindow; }
	        return this.send({
	            method: "PUT",
	            url: url,
	            headers: headers,
	            body: body
	        }, targetWindow);
	    };
	    HttpPostMessage.prototype.patch = function (url, body, headers, targetWindow) {
	        if (headers === void 0) { headers = {}; }
	        if (targetWindow === void 0) { targetWindow = this.defaultTargetWindow; }
	        return this.send({
	            method: "PATCH",
	            url: url,
	            headers: headers,
	            body: body
	        }, targetWindow);
	    };
	    HttpPostMessage.prototype.delete = function (url, body, headers, targetWindow) {
	        if (body === void 0) { body = null; }
	        if (headers === void 0) { headers = {}; }
	        if (targetWindow === void 0) { targetWindow = this.defaultTargetWindow; }
	        return this.send({
	            method: "DELETE",
	            url: url,
	            headers: headers,
	            body: body
	        }, targetWindow);
	    };
	    HttpPostMessage.prototype.send = function (request, targetWindow) {
	        if (targetWindow === void 0) { targetWindow = this.defaultTargetWindow; }
	        request.headers = this.assign({}, this.defaultHeaders, request.headers);
	        if (!targetWindow) {
	            throw new Error("target window is not provided.  You must either provide the target window explicitly as argument to request, or specify default target window when constructing instance of this class.");
	        }
	        return this.windowPostMessageProxy.postMessage(targetWindow, request);
	    };
	    /**
	     * Object.assign() polyfill
	     * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/assign
	     */
	    HttpPostMessage.prototype.assign = function (target) {
	        var sources = [];
	        for (var _i = 1; _i < arguments.length; _i++) {
	            sources[_i - 1] = arguments[_i];
	        }
	        if (target === undefined || target === null) {
	            throw new TypeError('Cannot convert undefined or null to object');
	        }
	        var output = Object(target);
	        sources.forEach(function (source) {
	            if (source !== undefined && source !== null) {
	                for (var nextKey in source) {
	                    if (Object.prototype.hasOwnProperty.call(source, nextKey)) {
	                        output[nextKey] = source[nextKey];
	                    }
	                }
	            }
	        });
	        return output;
	    };
	    return HttpPostMessage;
	}());
	exports.HttpPostMessage = HttpPostMessage;


/***/ }
/******/ ])
});
;
//# sourceMappingURL=httpPostMessage.js.map

/***/ }),

/***/ "./node_modules/powerbi-models/dist/models.js":
/*!****************************************************!*\
  !*** ./node_modules/powerbi-models/dist/models.js ***!
  \****************************************************/
/***/ (function(module) {

// powerbi-models v1.12.3
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
(function webpackUniversalModuleDefinition(root, factory) {
	if(true)
		module.exports = factory();
	else {}
})(this, () => {
return /******/ (() => { // webpackBootstrap
/******/ 	var __webpack_modules__ = ([
/* 0 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_612__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.SortDirection = exports.LegendPosition = exports.TextAlignment = exports.CommonErrorCodes = exports.BookmarksPlayMode = exports.ExportDataType = exports.QnaMode = exports.PageNavigationPosition = exports.DataCacheMode = exports.CredentialType = exports.isPercentOfGrandTotal = exports.isColumnAggr = exports.isHierarchyLevelAggr = exports.isHierarchyLevel = exports.isColumn = exports.isMeasure = exports.getFilterType = exports.isBasicFilterWithKeys = exports.isFilterKeyColumnsTarget = exports.HierarchyFilter = exports.AdvancedFilter = exports.TupleFilter = exports.IdentityFilter = exports.BasicFilterWithKeys = exports.BasicFilter = exports.RelativeTimeFilter = exports.RelativeDateFilter = exports.TopNFilter = exports.IncludeExcludeFilter = exports.NotSupportedFilter = exports.Filter = exports.RelativeDateOperators = exports.RelativeDateFilterTimeUnit = exports.FilterType = exports.FiltersLevel = exports.FiltersOperations = exports.MenuLocation = exports.ContrastMode = exports.TokenType = exports.ViewMode = exports.Permissions = exports.SectionVisibility = exports.ReportAlignment = exports.HyperlinkClickBehavior = exports.LayoutType = exports.VisualContainerDisplayMode = exports.BackgroundType = exports.DisplayOption = exports.PageSizeType = exports.TraceType = void 0;
exports.validateCommandsSettings = exports.validateVisualSettings = exports.validateVisualHeader = exports.validateExportDataRequest = exports.validateQnaInterpretInputData = exports.validateLoadQnaConfiguration = exports.validateSaveAsParameters = exports.validateUpdateFiltersRequest = exports.validateFilter = exports.validatePage = exports.validateTileLoad = exports.validateDashboardLoad = exports.validateQuickCreate = exports.validateCreateReport = exports.validatePaginatedReportLoad = exports.validateReportLoad = exports.validateMenuGroupExtension = exports.validateExtension = exports.validateCustomPageSize = exports.validateVisualizationsPane = exports.validateSyncSlicersPane = exports.validateSelectionPane = exports.validatePageNavigationPane = exports.validateFieldsPane = exports.validateFiltersPane = exports.validateBookmarksPane = exports.validatePanes = exports.validateSettings = exports.validateCaptureBookmarkRequest = exports.validateApplyBookmarkStateRequest = exports.validateApplyBookmarkByNameRequest = exports.validateAddBookmarkRequest = exports.validatePlayBookmarkRequest = exports.validateSlicerState = exports.validateSlicer = exports.validateVisualSelector = exports.isIExtensionArray = exports.isIExtensions = exports.isGroupedMenuExtension = exports.isFlatMenuExtension = exports.isReportFiltersArray = exports.isOnLoadFilters = exports.VisualDataRoleKindPreference = exports.VisualDataRoleKind = exports.CommandDisplayOption = exports.SlicerTargetSelector = exports.VisualTypeSelector = exports.VisualSelector = exports.PageSelector = exports.Selector = void 0;
exports.validateZoomLevel = exports.validateCustomTheme = void 0;
var validator_1 = __nested_webpack_require_612__(1);
var TraceType;
(function (TraceType) {
    TraceType[TraceType["Information"] = 0] = "Information";
    TraceType[TraceType["Verbose"] = 1] = "Verbose";
    TraceType[TraceType["Warning"] = 2] = "Warning";
    TraceType[TraceType["Error"] = 3] = "Error";
    TraceType[TraceType["ExpectedError"] = 4] = "ExpectedError";
    TraceType[TraceType["UnexpectedError"] = 5] = "UnexpectedError";
    TraceType[TraceType["Fatal"] = 6] = "Fatal";
})(TraceType = exports.TraceType || (exports.TraceType = {}));
var PageSizeType;
(function (PageSizeType) {
    PageSizeType[PageSizeType["Widescreen"] = 0] = "Widescreen";
    PageSizeType[PageSizeType["Standard"] = 1] = "Standard";
    PageSizeType[PageSizeType["Cortana"] = 2] = "Cortana";
    PageSizeType[PageSizeType["Letter"] = 3] = "Letter";
    PageSizeType[PageSizeType["Custom"] = 4] = "Custom";
    PageSizeType[PageSizeType["Mobile"] = 5] = "Mobile";
})(PageSizeType = exports.PageSizeType || (exports.PageSizeType = {}));
var DisplayOption;
(function (DisplayOption) {
    DisplayOption[DisplayOption["FitToPage"] = 0] = "FitToPage";
    DisplayOption[DisplayOption["FitToWidth"] = 1] = "FitToWidth";
    DisplayOption[DisplayOption["ActualSize"] = 2] = "ActualSize";
})(DisplayOption = exports.DisplayOption || (exports.DisplayOption = {}));
var BackgroundType;
(function (BackgroundType) {
    BackgroundType[BackgroundType["Default"] = 0] = "Default";
    BackgroundType[BackgroundType["Transparent"] = 1] = "Transparent";
})(BackgroundType = exports.BackgroundType || (exports.BackgroundType = {}));
var VisualContainerDisplayMode;
(function (VisualContainerDisplayMode) {
    VisualContainerDisplayMode[VisualContainerDisplayMode["Visible"] = 0] = "Visible";
    VisualContainerDisplayMode[VisualContainerDisplayMode["Hidden"] = 1] = "Hidden";
})(VisualContainerDisplayMode = exports.VisualContainerDisplayMode || (exports.VisualContainerDisplayMode = {}));
var LayoutType;
(function (LayoutType) {
    LayoutType[LayoutType["Master"] = 0] = "Master";
    LayoutType[LayoutType["Custom"] = 1] = "Custom";
    LayoutType[LayoutType["MobilePortrait"] = 2] = "MobilePortrait";
    LayoutType[LayoutType["MobileLandscape"] = 3] = "MobileLandscape";
})(LayoutType = exports.LayoutType || (exports.LayoutType = {}));
var HyperlinkClickBehavior;
(function (HyperlinkClickBehavior) {
    HyperlinkClickBehavior[HyperlinkClickBehavior["Navigate"] = 0] = "Navigate";
    HyperlinkClickBehavior[HyperlinkClickBehavior["NavigateAndRaiseEvent"] = 1] = "NavigateAndRaiseEvent";
    HyperlinkClickBehavior[HyperlinkClickBehavior["RaiseEvent"] = 2] = "RaiseEvent";
})(HyperlinkClickBehavior = exports.HyperlinkClickBehavior || (exports.HyperlinkClickBehavior = {}));
var ReportAlignment;
(function (ReportAlignment) {
    ReportAlignment[ReportAlignment["Left"] = 0] = "Left";
    ReportAlignment[ReportAlignment["Center"] = 1] = "Center";
    ReportAlignment[ReportAlignment["Right"] = 2] = "Right";
    ReportAlignment[ReportAlignment["None"] = 3] = "None";
})(ReportAlignment = exports.ReportAlignment || (exports.ReportAlignment = {}));
var SectionVisibility;
(function (SectionVisibility) {
    SectionVisibility[SectionVisibility["AlwaysVisible"] = 0] = "AlwaysVisible";
    SectionVisibility[SectionVisibility["HiddenInViewMode"] = 1] = "HiddenInViewMode";
})(SectionVisibility = exports.SectionVisibility || (exports.SectionVisibility = {}));
var Permissions;
(function (Permissions) {
    Permissions[Permissions["Read"] = 0] = "Read";
    Permissions[Permissions["ReadWrite"] = 1] = "ReadWrite";
    Permissions[Permissions["Copy"] = 2] = "Copy";
    Permissions[Permissions["Create"] = 4] = "Create";
    Permissions[Permissions["All"] = 7] = "All";
})(Permissions = exports.Permissions || (exports.Permissions = {}));
var ViewMode;
(function (ViewMode) {
    ViewMode[ViewMode["View"] = 0] = "View";
    ViewMode[ViewMode["Edit"] = 1] = "Edit";
})(ViewMode = exports.ViewMode || (exports.ViewMode = {}));
var TokenType;
(function (TokenType) {
    TokenType[TokenType["Aad"] = 0] = "Aad";
    TokenType[TokenType["Embed"] = 1] = "Embed";
})(TokenType = exports.TokenType || (exports.TokenType = {}));
var ContrastMode;
(function (ContrastMode) {
    ContrastMode[ContrastMode["None"] = 0] = "None";
    ContrastMode[ContrastMode["HighContrast1"] = 1] = "HighContrast1";
    ContrastMode[ContrastMode["HighContrast2"] = 2] = "HighContrast2";
    ContrastMode[ContrastMode["HighContrastBlack"] = 3] = "HighContrastBlack";
    ContrastMode[ContrastMode["HighContrastWhite"] = 4] = "HighContrastWhite";
})(ContrastMode = exports.ContrastMode || (exports.ContrastMode = {}));
var MenuLocation;
(function (MenuLocation) {
    MenuLocation[MenuLocation["Bottom"] = 0] = "Bottom";
    MenuLocation[MenuLocation["Top"] = 1] = "Top";
})(MenuLocation = exports.MenuLocation || (exports.MenuLocation = {}));
var FiltersOperations;
(function (FiltersOperations) {
    FiltersOperations[FiltersOperations["RemoveAll"] = 0] = "RemoveAll";
    FiltersOperations[FiltersOperations["ReplaceAll"] = 1] = "ReplaceAll";
    FiltersOperations[FiltersOperations["Add"] = 2] = "Add";
    FiltersOperations[FiltersOperations["Replace"] = 3] = "Replace";
})(FiltersOperations = exports.FiltersOperations || (exports.FiltersOperations = {}));
var FiltersLevel;
(function (FiltersLevel) {
    FiltersLevel[FiltersLevel["Report"] = 0] = "Report";
    FiltersLevel[FiltersLevel["Page"] = 1] = "Page";
    FiltersLevel[FiltersLevel["Visual"] = 2] = "Visual";
})(FiltersLevel = exports.FiltersLevel || (exports.FiltersLevel = {}));
var FilterType;
(function (FilterType) {
    FilterType[FilterType["Advanced"] = 0] = "Advanced";
    FilterType[FilterType["Basic"] = 1] = "Basic";
    FilterType[FilterType["Unknown"] = 2] = "Unknown";
    FilterType[FilterType["IncludeExclude"] = 3] = "IncludeExclude";
    FilterType[FilterType["RelativeDate"] = 4] = "RelativeDate";
    FilterType[FilterType["TopN"] = 5] = "TopN";
    FilterType[FilterType["Tuple"] = 6] = "Tuple";
    FilterType[FilterType["RelativeTime"] = 7] = "RelativeTime";
    FilterType[FilterType["Identity"] = 8] = "Identity";
    FilterType[FilterType["Hierarchy"] = 9] = "Hierarchy";
})(FilterType = exports.FilterType || (exports.FilterType = {}));
var RelativeDateFilterTimeUnit;
(function (RelativeDateFilterTimeUnit) {
    RelativeDateFilterTimeUnit[RelativeDateFilterTimeUnit["Days"] = 0] = "Days";
    RelativeDateFilterTimeUnit[RelativeDateFilterTimeUnit["Weeks"] = 1] = "Weeks";
    RelativeDateFilterTimeUnit[RelativeDateFilterTimeUnit["CalendarWeeks"] = 2] = "CalendarWeeks";
    RelativeDateFilterTimeUnit[RelativeDateFilterTimeUnit["Months"] = 3] = "Months";
    RelativeDateFilterTimeUnit[RelativeDateFilterTimeUnit["CalendarMonths"] = 4] = "CalendarMonths";
    RelativeDateFilterTimeUnit[RelativeDateFilterTimeUnit["Years"] = 5] = "Years";
    RelativeDateFilterTimeUnit[RelativeDateFilterTimeUnit["CalendarYears"] = 6] = "CalendarYears";
    RelativeDateFilterTimeUnit[RelativeDateFilterTimeUnit["Minutes"] = 7] = "Minutes";
    RelativeDateFilterTimeUnit[RelativeDateFilterTimeUnit["Hours"] = 8] = "Hours";
})(RelativeDateFilterTimeUnit = exports.RelativeDateFilterTimeUnit || (exports.RelativeDateFilterTimeUnit = {}));
var RelativeDateOperators;
(function (RelativeDateOperators) {
    RelativeDateOperators[RelativeDateOperators["InLast"] = 0] = "InLast";
    RelativeDateOperators[RelativeDateOperators["InThis"] = 1] = "InThis";
    RelativeDateOperators[RelativeDateOperators["InNext"] = 2] = "InNext";
})(RelativeDateOperators = exports.RelativeDateOperators || (exports.RelativeDateOperators = {}));
var Filter = /** @class */ (function () {
    function Filter(target, filterType) {
        this.target = target;
        this.filterType = filterType;
    }
    Filter.prototype.toJSON = function () {
        var filter = {
            $schema: this.schemaUrl,
            target: this.target,
            filterType: this.filterType
        };
        // Add displaySettings only when defined
        if (this.displaySettings !== undefined) {
            filter.displaySettings = this.displaySettings;
        }
        return filter;
    };
    return Filter;
}());
exports.Filter = Filter;
var NotSupportedFilter = /** @class */ (function (_super) {
    __extends(NotSupportedFilter, _super);
    function NotSupportedFilter(target, message, notSupportedTypeName) {
        var _this = _super.call(this, target, FilterType.Unknown) || this;
        _this.message = message;
        _this.notSupportedTypeName = notSupportedTypeName;
        _this.schemaUrl = NotSupportedFilter.schemaUrl;
        return _this;
    }
    NotSupportedFilter.prototype.toJSON = function () {
        var filter = _super.prototype.toJSON.call(this);
        filter.message = this.message;
        filter.notSupportedTypeName = this.notSupportedTypeName;
        return filter;
    };
    NotSupportedFilter.schemaUrl = "http://powerbi.com/product/schema#notSupported";
    return NotSupportedFilter;
}(Filter));
exports.NotSupportedFilter = NotSupportedFilter;
var IncludeExcludeFilter = /** @class */ (function (_super) {
    __extends(IncludeExcludeFilter, _super);
    function IncludeExcludeFilter(target, isExclude, values) {
        var _this = _super.call(this, target, FilterType.IncludeExclude) || this;
        _this.values = values;
        _this.isExclude = isExclude;
        _this.schemaUrl = IncludeExcludeFilter.schemaUrl;
        return _this;
    }
    IncludeExcludeFilter.prototype.toJSON = function () {
        var filter = _super.prototype.toJSON.call(this);
        filter.isExclude = this.isExclude;
        filter.values = this.values;
        return filter;
    };
    IncludeExcludeFilter.schemaUrl = "http://powerbi.com/product/schema#includeExclude";
    return IncludeExcludeFilter;
}(Filter));
exports.IncludeExcludeFilter = IncludeExcludeFilter;
var TopNFilter = /** @class */ (function (_super) {
    __extends(TopNFilter, _super);
    function TopNFilter(target, operator, itemCount, orderBy) {
        var _this = _super.call(this, target, FilterType.TopN) || this;
        _this.operator = operator;
        _this.itemCount = itemCount;
        _this.schemaUrl = TopNFilter.schemaUrl;
        _this.orderBy = orderBy;
        return _this;
    }
    TopNFilter.prototype.toJSON = function () {
        var filter = _super.prototype.toJSON.call(this);
        filter.operator = this.operator;
        filter.itemCount = this.itemCount;
        filter.orderBy = this.orderBy;
        return filter;
    };
    TopNFilter.schemaUrl = "http://powerbi.com/product/schema#topN";
    return TopNFilter;
}(Filter));
exports.TopNFilter = TopNFilter;
var RelativeDateFilter = /** @class */ (function (_super) {
    __extends(RelativeDateFilter, _super);
    function RelativeDateFilter(target, operator, timeUnitsCount, timeUnitType, includeToday) {
        var _this = _super.call(this, target, FilterType.RelativeDate) || this;
        _this.operator = operator;
        _this.timeUnitsCount = timeUnitsCount;
        _this.timeUnitType = timeUnitType;
        _this.includeToday = includeToday;
        _this.schemaUrl = RelativeDateFilter.schemaUrl;
        return _this;
    }
    RelativeDateFilter.prototype.toJSON = function () {
        var filter = _super.prototype.toJSON.call(this);
        filter.operator = this.operator;
        filter.timeUnitsCount = this.timeUnitsCount;
        filter.timeUnitType = this.timeUnitType;
        filter.includeToday = this.includeToday;
        return filter;
    };
    RelativeDateFilter.schemaUrl = "http://powerbi.com/product/schema#relativeDate";
    return RelativeDateFilter;
}(Filter));
exports.RelativeDateFilter = RelativeDateFilter;
var RelativeTimeFilter = /** @class */ (function (_super) {
    __extends(RelativeTimeFilter, _super);
    function RelativeTimeFilter(target, operator, timeUnitsCount, timeUnitType) {
        var _this = _super.call(this, target, FilterType.RelativeTime) || this;
        _this.operator = operator;
        _this.timeUnitsCount = timeUnitsCount;
        _this.timeUnitType = timeUnitType;
        _this.schemaUrl = RelativeTimeFilter.schemaUrl;
        return _this;
    }
    RelativeTimeFilter.prototype.toJSON = function () {
        var filter = _super.prototype.toJSON.call(this);
        filter.operator = this.operator;
        filter.timeUnitsCount = this.timeUnitsCount;
        filter.timeUnitType = this.timeUnitType;
        return filter;
    };
    RelativeTimeFilter.schemaUrl = "http://powerbi.com/product/schema#relativeTime";
    return RelativeTimeFilter;
}(Filter));
exports.RelativeTimeFilter = RelativeTimeFilter;
var BasicFilter = /** @class */ (function (_super) {
    __extends(BasicFilter, _super);
    function BasicFilter(target, operator) {
        var values = [];
        for (var _i = 2; _i < arguments.length; _i++) {
            values[_i - 2] = arguments[_i];
        }
        var _this = _super.call(this, target, FilterType.Basic) || this;
        _this.operator = operator;
        _this.schemaUrl = BasicFilter.schemaUrl;
        if (values.length === 0 && operator !== "All") {
            throw new Error("values must be a non-empty array unless your operator is \"All\".");
        }
        /**
         * Accept values as array instead of as individual arguments
         * new BasicFilter('a', 'b', 1, 2);
         * new BasicFilter('a', 'b', [1,2]);
         */
        if (Array.isArray(values[0])) {
            // eslint-disable-next-line @typescript-eslint/no-unnecessary-type-assertion
            _this.values = values[0];
        }
        else {
            _this.values = values;
        }
        return _this;
    }
    BasicFilter.prototype.toJSON = function () {
        var filter = _super.prototype.toJSON.call(this);
        filter.operator = this.operator;
        filter.values = this.values;
        filter.requireSingleSelection = !!this.requireSingleSelection;
        return filter;
    };
    BasicFilter.schemaUrl = "http://powerbi.com/product/schema#basic";
    return BasicFilter;
}(Filter));
exports.BasicFilter = BasicFilter;
var BasicFilterWithKeys = /** @class */ (function (_super) {
    __extends(BasicFilterWithKeys, _super);
    function BasicFilterWithKeys(target, operator, values, keyValues) {
        var _this = _super.call(this, target, operator, values) || this;
        _this.keyValues = keyValues;
        _this.target = target;
        var numberOfKeys = target.keys ? target.keys.length : 0;
        if (numberOfKeys > 0 && !keyValues) {
            throw new Error("You should pass the values to be filtered for each key. You passed: no values and ".concat(numberOfKeys, " keys"));
        }
        if (numberOfKeys === 0 && keyValues && keyValues.length > 0) {
            throw new Error("You passed key values but your target object doesn't contain the keys to be filtered");
        }
        for (var _i = 0, _a = _this.keyValues; _i < _a.length; _i++) {
            var keyValue = _a[_i];
            if (keyValue) {
                var lengthOfArray = keyValue.length;
                if (lengthOfArray !== numberOfKeys) {
                    throw new Error("Each tuple of key values should contain a value for each of the keys. You passed: ".concat(lengthOfArray, " values and ").concat(numberOfKeys, " keys"));
                }
            }
        }
        return _this;
    }
    BasicFilterWithKeys.prototype.toJSON = function () {
        var filter = _super.prototype.toJSON.call(this);
        filter.keyValues = this.keyValues;
        return filter;
    };
    return BasicFilterWithKeys;
}(BasicFilter));
exports.BasicFilterWithKeys = BasicFilterWithKeys;
var IdentityFilter = /** @class */ (function (_super) {
    __extends(IdentityFilter, _super);
    function IdentityFilter(target, operator) {
        var _this = _super.call(this, target, FilterType.Identity) || this;
        _this.operator = operator;
        _this.schemaUrl = IdentityFilter.schemaUrl;
        return _this;
    }
    IdentityFilter.prototype.toJSON = function () {
        var filter = _super.prototype.toJSON.call(this);
        filter.operator = this.operator;
        filter.target = this.target;
        return filter;
    };
    IdentityFilter.schemaUrl = "http://powerbi.com/product/schema#identity";
    return IdentityFilter;
}(Filter));
exports.IdentityFilter = IdentityFilter;
var TupleFilter = /** @class */ (function (_super) {
    __extends(TupleFilter, _super);
    function TupleFilter(target, operator, values) {
        var _this = _super.call(this, target, FilterType.Tuple) || this;
        _this.operator = operator;
        _this.schemaUrl = TupleFilter.schemaUrl;
        _this.values = values;
        return _this;
    }
    TupleFilter.prototype.toJSON = function () {
        var filter = _super.prototype.toJSON.call(this);
        filter.operator = this.operator;
        filter.values = this.values;
        filter.target = this.target;
        return filter;
    };
    TupleFilter.schemaUrl = "http://powerbi.com/product/schema#tuple";
    return TupleFilter;
}(Filter));
exports.TupleFilter = TupleFilter;
var AdvancedFilter = /** @class */ (function (_super) {
    __extends(AdvancedFilter, _super);
    function AdvancedFilter(target, logicalOperator) {
        var conditions = [];
        for (var _i = 2; _i < arguments.length; _i++) {
            conditions[_i - 2] = arguments[_i];
        }
        var _this = _super.call(this, target, FilterType.Advanced) || this;
        _this.schemaUrl = AdvancedFilter.schemaUrl;
        // Guard statements
        if (typeof logicalOperator !== "string" || logicalOperator.length === 0) {
            // TODO: It would be nicer to list out the possible logical operators.
            throw new Error("logicalOperator must be a valid operator, You passed: ".concat(logicalOperator));
        }
        _this.logicalOperator = logicalOperator;
        var extractedConditions;
        /**
         * Accept conditions as array instead of as individual arguments
         * new AdvancedFilter('a', 'b', "And", { value: 1, operator: "Equals" }, { value: 2, operator: "IsGreaterThan" });
         * new AdvancedFilter('a', 'b', "And", [{ value: 1, operator: "Equals" }, { value: 2, operator: "IsGreaterThan" }]);
         */
        if (Array.isArray(conditions[0])) {
            // eslint-disable-next-line @typescript-eslint/no-unnecessary-type-assertion
            extractedConditions = conditions[0];
        }
        else {
            extractedConditions = conditions;
        }
        if (extractedConditions.length > 2) {
            throw new Error("AdvancedFilters may not have more than two conditions. You passed: ".concat(conditions.length));
        }
        if (extractedConditions.length === 1 && logicalOperator !== "And") {
            throw new Error("Logical Operator must be \"And\" when there is only one condition provided");
        }
        _this.conditions = extractedConditions;
        return _this;
    }
    AdvancedFilter.prototype.toJSON = function () {
        var filter = _super.prototype.toJSON.call(this);
        filter.logicalOperator = this.logicalOperator;
        filter.conditions = this.conditions;
        return filter;
    };
    AdvancedFilter.schemaUrl = "http://powerbi.com/product/schema#advanced";
    return AdvancedFilter;
}(Filter));
exports.AdvancedFilter = AdvancedFilter;
var HierarchyFilter = /** @class */ (function (_super) {
    __extends(HierarchyFilter, _super);
    function HierarchyFilter(target, hierarchyData) {
        var _this = _super.call(this, target, FilterType.Hierarchy) || this;
        _this.schemaUrl = HierarchyFilter.schemaUrl;
        _this.hierarchyData = hierarchyData;
        return _this;
    }
    HierarchyFilter.prototype.toJSON = function () {
        var filter = _super.prototype.toJSON.call(this);
        filter.hierarchyData = this.hierarchyData;
        filter.target = this.target;
        return filter;
    };
    HierarchyFilter.schemaUrl = "http://powerbi.com/product/schema#hierarchy";
    return HierarchyFilter;
}(Filter));
exports.HierarchyFilter = HierarchyFilter;
function isFilterKeyColumnsTarget(target) {
    return isColumn(target) && !!target.keys;
}
exports.isFilterKeyColumnsTarget = isFilterKeyColumnsTarget;
function isBasicFilterWithKeys(filter) {
    return getFilterType(filter) === FilterType.Basic && !!filter.keyValues;
}
exports.isBasicFilterWithKeys = isBasicFilterWithKeys;
function getFilterType(filter) {
    if (filter.filterType) {
        return filter.filterType;
    }
    var basicFilter = filter;
    var advancedFilter = filter;
    if ((typeof basicFilter.operator === "string")
        && (Array.isArray(basicFilter.values))) {
        return FilterType.Basic;
    }
    else if ((typeof advancedFilter.logicalOperator === "string")
        && (Array.isArray(advancedFilter.conditions))) {
        return FilterType.Advanced;
    }
    else {
        return FilterType.Unknown;
    }
}
exports.getFilterType = getFilterType;
function isMeasure(arg) {
    return arg.table !== undefined && arg.measure !== undefined;
}
exports.isMeasure = isMeasure;
function isColumn(arg) {
    return !!(arg.table && arg.column && !arg.aggregationFunction);
}
exports.isColumn = isColumn;
function isHierarchyLevel(arg) {
    return !!(arg.table && arg.hierarchy && arg.hierarchyLevel && !arg.aggregationFunction);
}
exports.isHierarchyLevel = isHierarchyLevel;
function isHierarchyLevelAggr(arg) {
    return !!(arg.table && arg.hierarchy && arg.hierarchyLevel && arg.aggregationFunction);
}
exports.isHierarchyLevelAggr = isHierarchyLevelAggr;
function isColumnAggr(arg) {
    return !!(arg.table && arg.column && arg.aggregationFunction);
}
exports.isColumnAggr = isColumnAggr;
function isPercentOfGrandTotal(arg) {
    return !!arg.percentOfGrandTotal;
}
exports.isPercentOfGrandTotal = isPercentOfGrandTotal;
var CredentialType;
(function (CredentialType) {
    CredentialType[CredentialType["NoConnection"] = 0] = "NoConnection";
    CredentialType[CredentialType["OnBehalfOf"] = 1] = "OnBehalfOf";
    CredentialType[CredentialType["Anonymous"] = 2] = "Anonymous";
})(CredentialType = exports.CredentialType || (exports.CredentialType = {}));
var DataCacheMode;
(function (DataCacheMode) {
    DataCacheMode[DataCacheMode["Import"] = 0] = "Import";
    DataCacheMode[DataCacheMode["DirectQuery"] = 1] = "DirectQuery";
})(DataCacheMode = exports.DataCacheMode || (exports.DataCacheMode = {}));
var PageNavigationPosition;
(function (PageNavigationPosition) {
    PageNavigationPosition[PageNavigationPosition["Bottom"] = 0] = "Bottom";
    PageNavigationPosition[PageNavigationPosition["Left"] = 1] = "Left";
})(PageNavigationPosition = exports.PageNavigationPosition || (exports.PageNavigationPosition = {}));
var QnaMode;
(function (QnaMode) {
    QnaMode[QnaMode["Interactive"] = 0] = "Interactive";
    QnaMode[QnaMode["ResultOnly"] = 1] = "ResultOnly";
})(QnaMode = exports.QnaMode || (exports.QnaMode = {}));
var ExportDataType;
(function (ExportDataType) {
    ExportDataType[ExportDataType["Summarized"] = 0] = "Summarized";
    ExportDataType[ExportDataType["Underlying"] = 1] = "Underlying";
})(ExportDataType = exports.ExportDataType || (exports.ExportDataType = {}));
var BookmarksPlayMode;
(function (BookmarksPlayMode) {
    BookmarksPlayMode[BookmarksPlayMode["Off"] = 0] = "Off";
    BookmarksPlayMode[BookmarksPlayMode["Presentation"] = 1] = "Presentation";
})(BookmarksPlayMode = exports.BookmarksPlayMode || (exports.BookmarksPlayMode = {}));
// This is not an enum because enum strings require
// us to upgrade typeScript version and change SDK build definition
exports.CommonErrorCodes = {
    TokenExpired: 'TokenExpired',
    NotFound: 'PowerBIEntityNotFound',
    InvalidParameters: 'Invalid parameters',
    LoadReportFailed: 'LoadReportFailed',
    NotAuthorized: 'PowerBINotAuthorizedException',
    FailedToLoadModel: 'ExplorationContainer_FailedToLoadModel_DefaultDetails',
};
exports.TextAlignment = {
    Left: 'left',
    Center: 'center',
    Right: 'right',
};
exports.LegendPosition = {
    Top: 'Top',
    Bottom: 'Bottom',
    Right: 'Right',
    Left: 'Left',
    TopCenter: 'TopCenter',
    BottomCenter: 'BottomCenter',
    RightCenter: 'RightCenter',
    LeftCenter: 'LeftCenter',
};
var SortDirection;
(function (SortDirection) {
    SortDirection[SortDirection["Ascending"] = 1] = "Ascending";
    SortDirection[SortDirection["Descending"] = 2] = "Descending";
})(SortDirection = exports.SortDirection || (exports.SortDirection = {}));
var Selector = /** @class */ (function () {
    function Selector(schema) {
        this.$schema = schema;
    }
    Selector.prototype.toJSON = function () {
        return {
            $schema: this.$schema
        };
    };
    return Selector;
}());
exports.Selector = Selector;
var PageSelector = /** @class */ (function (_super) {
    __extends(PageSelector, _super);
    function PageSelector(pageName) {
        var _this = _super.call(this, PageSelector.schemaUrl) || this;
        _this.pageName = pageName;
        return _this;
    }
    PageSelector.prototype.toJSON = function () {
        var selector = _super.prototype.toJSON.call(this);
        selector.pageName = this.pageName;
        return selector;
    };
    PageSelector.schemaUrl = "http://powerbi.com/product/schema#pageSelector";
    return PageSelector;
}(Selector));
exports.PageSelector = PageSelector;
var VisualSelector = /** @class */ (function (_super) {
    __extends(VisualSelector, _super);
    function VisualSelector(visualName) {
        var _this = _super.call(this, VisualSelector.schemaUrl) || this;
        _this.visualName = visualName;
        return _this;
    }
    VisualSelector.prototype.toJSON = function () {
        var selector = _super.prototype.toJSON.call(this);
        selector.visualName = this.visualName;
        return selector;
    };
    VisualSelector.schemaUrl = "http://powerbi.com/product/schema#visualSelector";
    return VisualSelector;
}(Selector));
exports.VisualSelector = VisualSelector;
var VisualTypeSelector = /** @class */ (function (_super) {
    __extends(VisualTypeSelector, _super);
    function VisualTypeSelector(visualType) {
        var _this = _super.call(this, VisualSelector.schemaUrl) || this;
        _this.visualType = visualType;
        return _this;
    }
    VisualTypeSelector.prototype.toJSON = function () {
        var selector = _super.prototype.toJSON.call(this);
        selector.visualType = this.visualType;
        return selector;
    };
    VisualTypeSelector.schemaUrl = "http://powerbi.com/product/schema#visualTypeSelector";
    return VisualTypeSelector;
}(Selector));
exports.VisualTypeSelector = VisualTypeSelector;
var SlicerTargetSelector = /** @class */ (function (_super) {
    __extends(SlicerTargetSelector, _super);
    function SlicerTargetSelector(target) {
        var _this = _super.call(this, VisualSelector.schemaUrl) || this;
        _this.target = target;
        return _this;
    }
    SlicerTargetSelector.prototype.toJSON = function () {
        var selector = _super.prototype.toJSON.call(this);
        selector.target = this.target;
        return selector;
    };
    SlicerTargetSelector.schemaUrl = "http://powerbi.com/product/schema#slicerTargetSelector";
    return SlicerTargetSelector;
}(Selector));
exports.SlicerTargetSelector = SlicerTargetSelector;
var CommandDisplayOption;
(function (CommandDisplayOption) {
    CommandDisplayOption[CommandDisplayOption["Enabled"] = 0] = "Enabled";
    CommandDisplayOption[CommandDisplayOption["Disabled"] = 1] = "Disabled";
    CommandDisplayOption[CommandDisplayOption["Hidden"] = 2] = "Hidden";
})(CommandDisplayOption = exports.CommandDisplayOption || (exports.CommandDisplayOption = {}));
/*
 * Visual CRUD
 */
var VisualDataRoleKind;
(function (VisualDataRoleKind) {
    // Indicates that the role should be bound to something that evaluates to a grouping of values.
    VisualDataRoleKind[VisualDataRoleKind["Grouping"] = 0] = "Grouping";
    // Indicates that the role should be bound to something that evaluates to a single value in a scope.
    VisualDataRoleKind[VisualDataRoleKind["Measure"] = 1] = "Measure";
    // Indicates that the role can be bound to either Grouping or Measure.
    VisualDataRoleKind[VisualDataRoleKind["GroupingOrMeasure"] = 2] = "GroupingOrMeasure";
})(VisualDataRoleKind = exports.VisualDataRoleKind || (exports.VisualDataRoleKind = {}));
// Indicates the visual preference on Grouping or Measure. Only applicable if kind is GroupingOrMeasure.
var VisualDataRoleKindPreference;
(function (VisualDataRoleKindPreference) {
    VisualDataRoleKindPreference[VisualDataRoleKindPreference["Measure"] = 0] = "Measure";
    VisualDataRoleKindPreference[VisualDataRoleKindPreference["Grouping"] = 1] = "Grouping";
})(VisualDataRoleKindPreference = exports.VisualDataRoleKindPreference || (exports.VisualDataRoleKindPreference = {}));
function isOnLoadFilters(filters) {
    return filters && !isReportFiltersArray(filters);
}
exports.isOnLoadFilters = isOnLoadFilters;
function isReportFiltersArray(filters) {
    return Array.isArray(filters);
}
exports.isReportFiltersArray = isReportFiltersArray;
function isFlatMenuExtension(menuExtension) {
    return menuExtension && !isGroupedMenuExtension(menuExtension);
}
exports.isFlatMenuExtension = isFlatMenuExtension;
function isGroupedMenuExtension(menuExtension) {
    return menuExtension && !!menuExtension.groupName;
}
exports.isGroupedMenuExtension = isGroupedMenuExtension;
function isIExtensions(extensions) {
    return extensions && !isIExtensionArray(extensions);
}
exports.isIExtensions = isIExtensions;
function isIExtensionArray(extensions) {
    return Array.isArray(extensions);
}
exports.isIExtensionArray = isIExtensionArray;
function normalizeError(error) {
    var message = error.message;
    if (!message) {
        message = "".concat(error.path, " is invalid. Not meeting ").concat(error.keyword, " constraint");
    }
    return {
        message: message
    };
}
function validateVisualSelector(input) {
    var errors = validator_1.Validators.visualSelectorValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateVisualSelector = validateVisualSelector;
function validateSlicer(input) {
    var errors = validator_1.Validators.slicerValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateSlicer = validateSlicer;
function validateSlicerState(input) {
    var errors = validator_1.Validators.slicerStateValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateSlicerState = validateSlicerState;
function validatePlayBookmarkRequest(input) {
    var errors = validator_1.Validators.playBookmarkRequestValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validatePlayBookmarkRequest = validatePlayBookmarkRequest;
function validateAddBookmarkRequest(input) {
    var errors = validator_1.Validators.addBookmarkRequestValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateAddBookmarkRequest = validateAddBookmarkRequest;
function validateApplyBookmarkByNameRequest(input) {
    var errors = validator_1.Validators.applyBookmarkByNameRequestValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateApplyBookmarkByNameRequest = validateApplyBookmarkByNameRequest;
function validateApplyBookmarkStateRequest(input) {
    var errors = validator_1.Validators.applyBookmarkStateRequestValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateApplyBookmarkStateRequest = validateApplyBookmarkStateRequest;
function validateCaptureBookmarkRequest(input) {
    var errors = validator_1.Validators.captureBookmarkRequestValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateCaptureBookmarkRequest = validateCaptureBookmarkRequest;
function validateSettings(input) {
    var errors = validator_1.Validators.settingsValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateSettings = validateSettings;
function validatePanes(input) {
    var errors = validator_1.Validators.reportPanesValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validatePanes = validatePanes;
function validateBookmarksPane(input) {
    var errors = validator_1.Validators.bookmarksPaneValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateBookmarksPane = validateBookmarksPane;
function validateFiltersPane(input) {
    var errors = validator_1.Validators.filtersPaneValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateFiltersPane = validateFiltersPane;
function validateFieldsPane(input) {
    var errors = validator_1.Validators.fieldsPaneValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateFieldsPane = validateFieldsPane;
function validatePageNavigationPane(input) {
    var errors = validator_1.Validators.pageNavigationPaneValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validatePageNavigationPane = validatePageNavigationPane;
function validateSelectionPane(input) {
    var errors = validator_1.Validators.selectionPaneValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateSelectionPane = validateSelectionPane;
function validateSyncSlicersPane(input) {
    var errors = validator_1.Validators.syncSlicersPaneValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateSyncSlicersPane = validateSyncSlicersPane;
function validateVisualizationsPane(input) {
    var errors = validator_1.Validators.visualizationsPaneValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateVisualizationsPane = validateVisualizationsPane;
function validateCustomPageSize(input) {
    var errors = validator_1.Validators.customPageSizeValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateCustomPageSize = validateCustomPageSize;
function validateExtension(input) {
    var errors = validator_1.Validators.extensionValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateExtension = validateExtension;
function validateMenuGroupExtension(input) {
    var errors = validator_1.Validators.menuGroupExtensionValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateMenuGroupExtension = validateMenuGroupExtension;
function validateReportLoad(input) {
    var errors = validator_1.Validators.reportLoadValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateReportLoad = validateReportLoad;
function validatePaginatedReportLoad(input) {
    var errors = validator_1.Validators.paginatedReportLoadValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validatePaginatedReportLoad = validatePaginatedReportLoad;
function validateCreateReport(input) {
    var errors = validator_1.Validators.reportCreateValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateCreateReport = validateCreateReport;
function validateQuickCreate(input) {
    var errors = validator_1.Validators.quickCreateValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateQuickCreate = validateQuickCreate;
function validateDashboardLoad(input) {
    var errors = validator_1.Validators.dashboardLoadValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateDashboardLoad = validateDashboardLoad;
function validateTileLoad(input) {
    var errors = validator_1.Validators.tileLoadValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateTileLoad = validateTileLoad;
function validatePage(input) {
    var errors = validator_1.Validators.pageValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validatePage = validatePage;
function validateFilter(input) {
    var errors = validator_1.Validators.filterValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateFilter = validateFilter;
function validateUpdateFiltersRequest(input) {
    var errors = validator_1.Validators.updateFiltersRequestValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateUpdateFiltersRequest = validateUpdateFiltersRequest;
function validateSaveAsParameters(input) {
    var errors = validator_1.Validators.saveAsParametersValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateSaveAsParameters = validateSaveAsParameters;
function validateLoadQnaConfiguration(input) {
    var errors = validator_1.Validators.loadQnaValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateLoadQnaConfiguration = validateLoadQnaConfiguration;
function validateQnaInterpretInputData(input) {
    var errors = validator_1.Validators.qnaInterpretInputDataValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateQnaInterpretInputData = validateQnaInterpretInputData;
function validateExportDataRequest(input) {
    var errors = validator_1.Validators.exportDataRequestValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateExportDataRequest = validateExportDataRequest;
function validateVisualHeader(input) {
    var errors = validator_1.Validators.visualHeaderValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateVisualHeader = validateVisualHeader;
function validateVisualSettings(input) {
    var errors = validator_1.Validators.visualSettingsValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateVisualSettings = validateVisualSettings;
function validateCommandsSettings(input) {
    var errors = validator_1.Validators.commandsSettingsValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateCommandsSettings = validateCommandsSettings;
function validateCustomTheme(input) {
    var errors = validator_1.Validators.customThemeValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateCustomTheme = validateCustomTheme;
function validateZoomLevel(input) {
    var errors = validator_1.Validators.zoomLevelValidator.validate(input);
    return errors ? errors.map(normalizeError) : undefined;
}
exports.validateZoomLevel = validateZoomLevel;


/***/ }),
/* 1 */
/***/ ((__unused_webpack_module, exports, __nested_webpack_require_44757__) => {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.Validators = void 0;
var barsValidator_1 = __nested_webpack_require_44757__(2);
var bookmarkValidator_1 = __nested_webpack_require_44757__(5);
var commandsSettingsValidator_1 = __nested_webpack_require_44757__(6);
var customThemeValidator_1 = __nested_webpack_require_44757__(7);
var dashboardLoadValidator_1 = __nested_webpack_require_44757__(8);
var datasetBindingValidator_1 = __nested_webpack_require_44757__(9);
var exportDataValidator_1 = __nested_webpack_require_44757__(10);
var extensionsValidator_1 = __nested_webpack_require_44757__(11);
var filtersValidator_1 = __nested_webpack_require_44757__(12);
var layoutValidator_1 = __nested_webpack_require_44757__(13);
var pageValidator_1 = __nested_webpack_require_44757__(14);
var panesValidator_1 = __nested_webpack_require_44757__(15);
var qnaValidator_1 = __nested_webpack_require_44757__(16);
var reportCreateValidator_1 = __nested_webpack_require_44757__(17);
var reportLoadValidator_1 = __nested_webpack_require_44757__(18);
var paginatedReportLoadValidator_1 = __nested_webpack_require_44757__(19);
var saveAsParametersValidator_1 = __nested_webpack_require_44757__(20);
var selectorsValidator_1 = __nested_webpack_require_44757__(21);
var settingsValidator_1 = __nested_webpack_require_44757__(22);
var slicersValidator_1 = __nested_webpack_require_44757__(23);
var tileLoadValidator_1 = __nested_webpack_require_44757__(24);
var visualSettingsValidator_1 = __nested_webpack_require_44757__(25);
var anyOfValidator_1 = __nested_webpack_require_44757__(26);
var fieldForbiddenValidator_1 = __nested_webpack_require_44757__(27);
var fieldRequiredValidator_1 = __nested_webpack_require_44757__(28);
var mapValidator_1 = __nested_webpack_require_44757__(29);
var typeValidator_1 = __nested_webpack_require_44757__(4);
var parameterPanelValidator_1 = __nested_webpack_require_44757__(30);
var datasetCreateConfigValidator_1 = __nested_webpack_require_44757__(31);
var quickCreateValidator_1 = __nested_webpack_require_44757__(32);
exports.Validators = {
    addBookmarkRequestValidator: new bookmarkValidator_1.AddBookmarkRequestValidator(),
    advancedFilterTypeValidator: new typeValidator_1.EnumValidator([0]),
    advancedFilterValidator: new filtersValidator_1.AdvancedFilterValidator(),
    anyArrayValidator: new typeValidator_1.ArrayValidator([new anyOfValidator_1.AnyOfValidator([new typeValidator_1.StringValidator(), new typeValidator_1.NumberValidator(), new typeValidator_1.BooleanValidator()])]),
    anyFilterValidator: new anyOfValidator_1.AnyOfValidator([new filtersValidator_1.BasicFilterValidator(), new filtersValidator_1.AdvancedFilterValidator(), new filtersValidator_1.IncludeExcludeFilterValidator(), new filtersValidator_1.NotSupportedFilterValidator(), new filtersValidator_1.RelativeDateFilterValidator(), new filtersValidator_1.TopNFilterValidator(), new filtersValidator_1.RelativeTimeFilterValidator(), new filtersValidator_1.HierarchyFilterValidator()]),
    anyValueValidator: new anyOfValidator_1.AnyOfValidator([new typeValidator_1.StringValidator(), new typeValidator_1.NumberValidator(), new typeValidator_1.BooleanValidator()]),
    actionBarValidator: new barsValidator_1.ActionBarValidator(),
    statusBarValidator: new barsValidator_1.StatusBarValidator(),
    applyBookmarkByNameRequestValidator: new bookmarkValidator_1.ApplyBookmarkByNameRequestValidator(),
    applyBookmarkStateRequestValidator: new bookmarkValidator_1.ApplyBookmarkStateRequestValidator(),
    applyBookmarkValidator: new anyOfValidator_1.AnyOfValidator([new bookmarkValidator_1.ApplyBookmarkByNameRequestValidator(), new bookmarkValidator_1.ApplyBookmarkStateRequestValidator()]),
    backgroundValidator: new typeValidator_1.EnumValidator([0, 1]),
    basicFilterTypeValidator: new typeValidator_1.EnumValidator([1]),
    basicFilterValidator: new filtersValidator_1.BasicFilterValidator(),
    booleanArrayValidator: new typeValidator_1.BooleanArrayValidator(),
    booleanValidator: new typeValidator_1.BooleanValidator(),
    bookmarksPaneValidator: new panesValidator_1.BookmarksPaneValidator(),
    captureBookmarkOptionsValidator: new bookmarkValidator_1.CaptureBookmarkOptionsValidator(),
    captureBookmarkRequestValidator: new bookmarkValidator_1.CaptureBookmarkRequestValidator(),
    columnSchemaArrayValidator: new typeValidator_1.ArrayValidator([new datasetCreateConfigValidator_1.ColumnSchemaValidator()]),
    commandDisplayOptionValidator: new typeValidator_1.EnumValidator([0, 1, 2]),
    commandExtensionSelectorValidator: new anyOfValidator_1.AnyOfValidator([new selectorsValidator_1.VisualSelectorValidator(), new selectorsValidator_1.VisualTypeSelectorValidator()]),
    commandExtensionArrayValidator: new typeValidator_1.ArrayValidator([new extensionsValidator_1.CommandExtensionValidator()]),
    commandExtensionValidator: new extensionsValidator_1.CommandExtensionValidator(),
    commandsSettingsArrayValidator: new typeValidator_1.ArrayValidator([new commandsSettingsValidator_1.CommandsSettingsValidator()]),
    commandsSettingsValidator: new commandsSettingsValidator_1.CommandsSettingsValidator(),
    conditionItemValidator: new filtersValidator_1.ConditionItemValidator(),
    contrastModeValidator: new typeValidator_1.EnumValidator([0, 1, 2, 3, 4]),
    credentialDetailsValidator: new mapValidator_1.MapValidator([new typeValidator_1.StringValidator()], [new typeValidator_1.StringValidator()]),
    credentialsValidator: new datasetCreateConfigValidator_1.CredentialsValidator(),
    credentialTypeValidator: new typeValidator_1.EnumValidator([0, 1, 2]),
    customLayoutDisplayOptionValidator: new typeValidator_1.EnumValidator([0, 1, 2]),
    customLayoutValidator: new layoutValidator_1.CustomLayoutValidator(),
    customPageSizeValidator: new pageValidator_1.CustomPageSizeValidator(),
    customThemeValidator: new customThemeValidator_1.CustomThemeValidator(),
    dashboardLoadValidator: new dashboardLoadValidator_1.DashboardLoadValidator(),
    dataCacheModeValidator: new typeValidator_1.EnumValidator([0, 1]),
    datasetBindingValidator: new datasetBindingValidator_1.DatasetBindingValidator(),
    datasetCreateConfigValidator: new datasetCreateConfigValidator_1.DatasetCreateConfigValidator(),
    datasourceConnectionConfigValidator: new datasetCreateConfigValidator_1.DatasourceConnectionConfigValidator(),
    displayStateModeValidator: new typeValidator_1.EnumValidator([0, 1]),
    displayStateValidator: new layoutValidator_1.DisplayStateValidator(),
    exportDataRequestValidator: new exportDataValidator_1.ExportDataRequestValidator(),
    extensionArrayValidator: new typeValidator_1.ArrayValidator([new extensionsValidator_1.ExtensionValidator()]),
    extensionsValidator: new anyOfValidator_1.AnyOfValidator([new typeValidator_1.ArrayValidator([new extensionsValidator_1.ExtensionValidator()]), new extensionsValidator_1.ExtensionsValidator()]),
    extensionPointsValidator: new extensionsValidator_1.ExtensionPointsValidator(),
    extensionValidator: new extensionsValidator_1.ExtensionValidator(),
    fieldForbiddenValidator: new fieldForbiddenValidator_1.FieldForbiddenValidator(),
    fieldRequiredValidator: new fieldRequiredValidator_1.FieldRequiredValidator(),
    fieldsPaneValidator: new panesValidator_1.FieldsPaneValidator(),
    filterColumnTargetValidator: new filtersValidator_1.FilterColumnTargetValidator(),
    filterDisplaySettingsValidator: new filtersValidator_1.FilterDisplaySettingsValidator(),
    filterConditionsValidator: new typeValidator_1.ArrayValidator([new filtersValidator_1.ConditionItemValidator()]),
    filterHierarchyTargetValidator: new filtersValidator_1.FilterHierarchyTargetValidator(),
    filterMeasureTargetValidator: new filtersValidator_1.FilterMeasureTargetValidator(),
    filterTargetValidator: new anyOfValidator_1.AnyOfValidator([new filtersValidator_1.FilterColumnTargetValidator(), new filtersValidator_1.FilterHierarchyTargetValidator(), new filtersValidator_1.FilterMeasureTargetValidator(), new typeValidator_1.ArrayValidator([new anyOfValidator_1.AnyOfValidator([new filtersValidator_1.FilterColumnTargetValidator(), new filtersValidator_1.FilterHierarchyTargetValidator(), new filtersValidator_1.FilterMeasureTargetValidator(), new filtersValidator_1.FilterKeyColumnsTargetValidator(), new filtersValidator_1.FilterKeyHierarchyTargetValidator()])])]),
    filterValidator: new filtersValidator_1.FilterValidator(),
    filterTypeValidator: new typeValidator_1.EnumValidator([0, 1, 2, 3, 4, 5, 6, 7, 9]),
    filtersArrayValidator: new typeValidator_1.ArrayValidator([new filtersValidator_1.FilterValidator()]),
    filtersOperationsUpdateValidator: new typeValidator_1.EnumValidator([1, 2, 3]),
    filtersOperationsRemoveAllValidator: new typeValidator_1.EnumValidator([0]),
    filtersPaneValidator: new panesValidator_1.FiltersPaneValidator(),
    hyperlinkClickBehaviorValidator: new typeValidator_1.EnumValidator([0, 1, 2]),
    includeExcludeFilterValidator: new filtersValidator_1.IncludeExcludeFilterValidator(),
    includeExludeFilterTypeValidator: new typeValidator_1.EnumValidator([3]),
    hierarchyFilterTypeValidator: new typeValidator_1.EnumValidator([9]),
    hierarchyFilterValuesValidator: new typeValidator_1.ArrayValidator([new filtersValidator_1.HierarchyFilterNodeValidator()]),
    layoutTypeValidator: new typeValidator_1.EnumValidator([0, 1, 2, 3]),
    loadQnaValidator: new qnaValidator_1.LoadQnaValidator(),
    menuExtensionValidator: new anyOfValidator_1.AnyOfValidator([new extensionsValidator_1.FlatMenuExtensionValidator(), new extensionsValidator_1.GroupedMenuExtensionValidator()]),
    menuGroupExtensionArrayValidator: new typeValidator_1.ArrayValidator([new extensionsValidator_1.MenuGroupExtensionValidator()]),
    menuGroupExtensionValidator: new extensionsValidator_1.MenuGroupExtensionValidator(),
    menuLocationValidator: new typeValidator_1.EnumValidator([0, 1]),
    notSupportedFilterTypeValidator: new typeValidator_1.EnumValidator([2]),
    notSupportedFilterValidator: new filtersValidator_1.NotSupportedFilterValidator(),
    numberArrayValidator: new typeValidator_1.NumberArrayValidator(),
    numberValidator: new typeValidator_1.NumberValidator(),
    onLoadFiltersBaseValidator: new anyOfValidator_1.AnyOfValidator([new filtersValidator_1.OnLoadFiltersBaseValidator(), new filtersValidator_1.OnLoadFiltersBaseRemoveOperationValidator()]),
    pageLayoutValidator: new mapValidator_1.MapValidator([new typeValidator_1.StringValidator()], [new layoutValidator_1.VisualLayoutValidator()]),
    pageNavigationPaneValidator: new panesValidator_1.PageNavigationPaneValidator(),
    pageNavigationPositionValidator: new typeValidator_1.EnumValidator([0, 1]),
    pageSizeTypeValidator: new typeValidator_1.EnumValidator([0, 1, 2, 3, 4, 5]),
    pageSizeValidator: new pageValidator_1.PageSizeValidator(),
    pageValidator: new pageValidator_1.PageValidator(),
    pageViewFieldValidator: new pageValidator_1.PageViewFieldValidator(),
    pagesLayoutValidator: new mapValidator_1.MapValidator([new typeValidator_1.StringValidator()], [new layoutValidator_1.PageLayoutValidator()]),
    paginatedReportCommandsValidator: new commandsSettingsValidator_1.PaginatedReportCommandsValidator(),
    paginatedReportLoadValidator: new paginatedReportLoadValidator_1.PaginatedReportLoadValidator(),
    paginatedReportsettingsValidator: new settingsValidator_1.PaginatedReportSettingsValidator(),
    parameterValuesArrayValidator: new typeValidator_1.ArrayValidator([new paginatedReportLoadValidator_1.ReportParameterFieldsValidator()]),
    parametersPanelValidator: new parameterPanelValidator_1.ParametersPanelValidator(),
    permissionsValidator: new typeValidator_1.EnumValidator([0, 1, 2, 4, 7]),
    playBookmarkRequestValidator: new bookmarkValidator_1.PlayBookmarkRequestValidator(),
    qnaInterpretInputDataValidator: new qnaValidator_1.QnaInterpretInputDataValidator(),
    qnaPanesValidator: new panesValidator_1.QnaPanesValidator(),
    qnaSettingValidator: new qnaValidator_1.QnaSettingsValidator(),
    quickCreateValidator: new quickCreateValidator_1.QuickCreateValidator(),
    rawDataValidator: new typeValidator_1.ArrayValidator([new typeValidator_1.ArrayValidator([new typeValidator_1.StringValidator()])]),
    relativeDateFilterOperatorValidator: new typeValidator_1.EnumValidator([0, 1, 2]),
    relativeDateFilterTimeUnitTypeValidator: new typeValidator_1.EnumValidator([0, 1, 2, 3, 4, 5, 6]),
    relativeDateFilterTypeValidator: new typeValidator_1.EnumValidator([4]),
    relativeDateFilterValidator: new filtersValidator_1.RelativeDateFilterValidator(),
    relativeDateTimeFilterTypeValidator: new typeValidator_1.EnumValidator([4, 7]),
    relativeDateTimeFilterUnitTypeValidator: new typeValidator_1.EnumValidator([0, 1, 2, 3, 4, 5, 6, 7, 8]),
    relativeTimeFilterTimeUnitTypeValidator: new typeValidator_1.EnumValidator([7, 8]),
    relativeTimeFilterTypeValidator: new typeValidator_1.EnumValidator([7]),
    relativeTimeFilterValidator: new filtersValidator_1.RelativeTimeFilterValidator(),
    reportBarsValidator: new barsValidator_1.ReportBarsValidator(),
    reportCreateValidator: new reportCreateValidator_1.ReportCreateValidator(),
    reportLoadFiltersValidator: new anyOfValidator_1.AnyOfValidator([new typeValidator_1.ArrayValidator([new filtersValidator_1.FilterValidator()]), new filtersValidator_1.OnLoadFiltersValidator()]),
    reportLoadValidator: new reportLoadValidator_1.ReportLoadValidator(),
    reportPanesValidator: new panesValidator_1.ReportPanesValidator(),
    saveAsParametersValidator: new saveAsParametersValidator_1.SaveAsParametersValidator(),
    selectionPaneValidator: new panesValidator_1.SelectionPaneValidator(),
    settingsValidator: new settingsValidator_1.SettingsValidator(),
    singleCommandSettingsValidator: new commandsSettingsValidator_1.SingleCommandSettingsValidator(),
    slicerSelectorValidator: new anyOfValidator_1.AnyOfValidator([new selectorsValidator_1.VisualSelectorValidator(), new selectorsValidator_1.SlicerTargetSelectorValidator()]),
    slicerStateValidator: new slicersValidator_1.SlicerStateValidator(),
    slicerTargetValidator: new anyOfValidator_1.AnyOfValidator([new filtersValidator_1.FilterColumnTargetValidator(), new filtersValidator_1.FilterHierarchyTargetValidator(), new filtersValidator_1.FilterMeasureTargetValidator(), new filtersValidator_1.FilterKeyColumnsTargetValidator(), new filtersValidator_1.FilterKeyHierarchyTargetValidator()]),
    slicerValidator: new slicersValidator_1.SlicerValidator(),
    stringArrayValidator: new typeValidator_1.StringArrayValidator(),
    stringValidator: new typeValidator_1.StringValidator(),
    syncSlicersPaneValidator: new panesValidator_1.SyncSlicersPaneValidator(),
    tableDataArrayValidator: new typeValidator_1.ArrayValidator([new datasetCreateConfigValidator_1.TableDataValidator()]),
    tableSchemaListValidator: new typeValidator_1.ArrayValidator([new datasetCreateConfigValidator_1.TableSchemaValidator()]),
    tileLoadValidator: new tileLoadValidator_1.TileLoadValidator(),
    tokenTypeValidator: new typeValidator_1.EnumValidator([0, 1]),
    topNFilterTypeValidator: new typeValidator_1.EnumValidator([5]),
    topNFilterValidator: new filtersValidator_1.TopNFilterValidator(),
    updateFiltersRequestValidator: new anyOfValidator_1.AnyOfValidator([new filtersValidator_1.UpdateFiltersRequestValidator(), new filtersValidator_1.RemoveFiltersRequestValidator()]),
    viewModeValidator: new typeValidator_1.EnumValidator([0, 1]),
    visualCommandSelectorValidator: new anyOfValidator_1.AnyOfValidator([new selectorsValidator_1.VisualSelectorValidator(), new selectorsValidator_1.VisualTypeSelectorValidator()]),
    visualHeaderSelectorValidator: new anyOfValidator_1.AnyOfValidator([new selectorsValidator_1.VisualSelectorValidator(), new selectorsValidator_1.VisualTypeSelectorValidator()]),
    visualHeaderSettingsValidator: new visualSettingsValidator_1.VisualHeaderSettingsValidator(),
    visualHeaderValidator: new visualSettingsValidator_1.VisualHeaderValidator(),
    visualHeadersValidator: new typeValidator_1.ArrayValidator([new visualSettingsValidator_1.VisualHeaderValidator()]),
    visualizationsPaneValidator: new panesValidator_1.VisualizationsPaneValidator(),
    visualLayoutValidator: new layoutValidator_1.VisualLayoutValidator(),
    visualSelectorValidator: new selectorsValidator_1.VisualSelectorValidator(),
    visualSettingsValidator: new visualSettingsValidator_1.VisualSettingsValidator(),
    visualTypeSelectorValidator: new selectorsValidator_1.VisualTypeSelectorValidator(),
    zoomLevelValidator: new typeValidator_1.RangeValidator(0.25, 4),
};


/***/ }),
/* 2 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_61501__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.StatusBarValidator = exports.ActionBarValidator = exports.ReportBarsValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_61501__(3);
var typeValidator_1 = __nested_webpack_require_61501__(4);
var validator_1 = __nested_webpack_require_61501__(1);
var ReportBarsValidator = /** @class */ (function (_super) {
    __extends(ReportBarsValidator, _super);
    function ReportBarsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ReportBarsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "actionBar",
                validators: [validator_1.Validators.actionBarValidator]
            },
            {
                field: "statusBar",
                validators: [validator_1.Validators.statusBarValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ReportBarsValidator;
}(typeValidator_1.ObjectValidator));
exports.ReportBarsValidator = ReportBarsValidator;
var ActionBarValidator = /** @class */ (function (_super) {
    __extends(ActionBarValidator, _super);
    function ActionBarValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ActionBarValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "visible",
                validators: [validator_1.Validators.booleanValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ActionBarValidator;
}(typeValidator_1.ObjectValidator));
exports.ActionBarValidator = ActionBarValidator;
var StatusBarValidator = /** @class */ (function (_super) {
    __extends(StatusBarValidator, _super);
    function StatusBarValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    StatusBarValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "visible",
                validators: [validator_1.Validators.booleanValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return StatusBarValidator;
}(typeValidator_1.ObjectValidator));
exports.StatusBarValidator = StatusBarValidator;


/***/ }),
/* 3 */
/***/ ((__unused_webpack_module, exports) => {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.MultipleFieldsValidator = void 0;
var MultipleFieldsValidator = /** @class */ (function () {
    function MultipleFieldsValidator(fieldValidatorsPairs) {
        this.fieldValidatorsPairs = fieldValidatorsPairs;
    }
    MultipleFieldsValidator.prototype.validate = function (input, path, field) {
        if (!this.fieldValidatorsPairs) {
            return null;
        }
        var fieldsPath = path ? path + "." + field : field;
        for (var _i = 0, _a = this.fieldValidatorsPairs; _i < _a.length; _i++) {
            var fieldValidators = _a[_i];
            for (var _b = 0, _c = fieldValidators.validators; _b < _c.length; _b++) {
                var validator = _c[_b];
                var errors = validator.validate(input[fieldValidators.field], fieldsPath, fieldValidators.field);
                if (errors) {
                    return errors;
                }
            }
        }
        return null;
    };
    return MultipleFieldsValidator;
}());
exports.MultipleFieldsValidator = MultipleFieldsValidator;


/***/ }),
/* 4 */
/***/ (function(__unused_webpack_module, exports) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.RangeValidator = exports.NumberArrayValidator = exports.BooleanArrayValidator = exports.StringArrayValidator = exports.EnumValidator = exports.SchemaValidator = exports.ValueValidator = exports.NumberValidator = exports.BooleanValidator = exports.StringValidator = exports.TypeValidator = exports.ArrayValidator = exports.ObjectValidator = void 0;
var ObjectValidator = /** @class */ (function () {
    function ObjectValidator() {
    }
    ObjectValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        if (typeof input !== "object" || Array.isArray(input)) {
            return [{
                    message: field !== undefined ? field + " must be an object" : "input must be an object",
                    path: path,
                    keyword: "type"
                }];
        }
        return null;
    };
    return ObjectValidator;
}());
exports.ObjectValidator = ObjectValidator;
var ArrayValidator = /** @class */ (function () {
    function ArrayValidator(itemValidators) {
        this.itemValidators = itemValidators;
    }
    ArrayValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        if (!(Array.isArray(input))) {
            return [{
                    message: field + " property is invalid",
                    path: (path ? path + "." : "") + field,
                    keyword: "type"
                }];
        }
        for (var i = 0; i < input.length; i++) {
            var fieldsPath = (path ? path + "." : "") + field + "." + i.toString();
            for (var _i = 0, _a = this.itemValidators; _i < _a.length; _i++) {
                var validator = _a[_i];
                var errors = validator.validate(input[i], fieldsPath, field);
                if (errors) {
                    return [{
                            message: field + " property is invalid",
                            path: (path ? path + "." : "") + field,
                            keyword: "type"
                        }];
                }
            }
        }
        return null;
    };
    return ArrayValidator;
}());
exports.ArrayValidator = ArrayValidator;
var TypeValidator = /** @class */ (function () {
    function TypeValidator(expectedType) {
        this.expectedType = expectedType;
    }
    TypeValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        if (!(typeof input === this.expectedType)) {
            return [{
                    message: field + " must be a " + this.expectedType,
                    path: (path ? path + "." : "") + field,
                    keyword: "type"
                }];
        }
        return null;
    };
    return TypeValidator;
}());
exports.TypeValidator = TypeValidator;
var StringValidator = /** @class */ (function (_super) {
    __extends(StringValidator, _super);
    function StringValidator() {
        return _super.call(this, "string") || this;
    }
    return StringValidator;
}(TypeValidator));
exports.StringValidator = StringValidator;
var BooleanValidator = /** @class */ (function (_super) {
    __extends(BooleanValidator, _super);
    function BooleanValidator() {
        return _super.call(this, "boolean") || this;
    }
    return BooleanValidator;
}(TypeValidator));
exports.BooleanValidator = BooleanValidator;
var NumberValidator = /** @class */ (function (_super) {
    __extends(NumberValidator, _super);
    function NumberValidator() {
        return _super.call(this, "number") || this;
    }
    return NumberValidator;
}(TypeValidator));
exports.NumberValidator = NumberValidator;
var ValueValidator = /** @class */ (function () {
    function ValueValidator(possibleValues) {
        this.possibleValues = possibleValues;
    }
    ValueValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        if (this.possibleValues.indexOf(input) < 0) {
            return [{
                    message: field + " property is invalid",
                    path: (path ? path + "." : "") + field,
                    keyword: "invalid"
                }];
        }
        return null;
    };
    return ValueValidator;
}());
exports.ValueValidator = ValueValidator;
var SchemaValidator = /** @class */ (function (_super) {
    __extends(SchemaValidator, _super);
    function SchemaValidator(schemaValue) {
        var _this = _super.call(this, [schemaValue]) || this;
        _this.schemaValue = schemaValue;
        return _this;
    }
    SchemaValidator.prototype.validate = function (input, path, field) {
        return _super.prototype.validate.call(this, input, path, field);
    };
    return SchemaValidator;
}(ValueValidator));
exports.SchemaValidator = SchemaValidator;
var EnumValidator = /** @class */ (function (_super) {
    __extends(EnumValidator, _super);
    function EnumValidator(possibleValues) {
        var _this = _super.call(this) || this;
        _this.possibleValues = possibleValues;
        return _this;
    }
    EnumValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var valueValidator = new ValueValidator(this.possibleValues);
        return valueValidator.validate(input, path, field);
    };
    return EnumValidator;
}(NumberValidator));
exports.EnumValidator = EnumValidator;
var StringArrayValidator = /** @class */ (function (_super) {
    __extends(StringArrayValidator, _super);
    function StringArrayValidator() {
        return _super.call(this, [new StringValidator()]) || this;
    }
    StringArrayValidator.prototype.validate = function (input, path, field) {
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return [{
                    message: field + " must be an array of strings",
                    path: (path ? path + "." : "") + field,
                    keyword: "type"
                }];
        }
        return null;
    };
    return StringArrayValidator;
}(ArrayValidator));
exports.StringArrayValidator = StringArrayValidator;
var BooleanArrayValidator = /** @class */ (function (_super) {
    __extends(BooleanArrayValidator, _super);
    function BooleanArrayValidator() {
        return _super.call(this, [new BooleanValidator()]) || this;
    }
    BooleanArrayValidator.prototype.validate = function (input, path, field) {
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return [{
                    message: field + " must be an array of booleans",
                    path: (path ? path + "." : "") + field,
                    keyword: "type"
                }];
        }
        return null;
    };
    return BooleanArrayValidator;
}(ArrayValidator));
exports.BooleanArrayValidator = BooleanArrayValidator;
var NumberArrayValidator = /** @class */ (function (_super) {
    __extends(NumberArrayValidator, _super);
    function NumberArrayValidator() {
        return _super.call(this, [new NumberValidator()]) || this;
    }
    NumberArrayValidator.prototype.validate = function (input, path, field) {
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return [{
                    message: field + " must be an array of numbers",
                    path: (path ? path + "." : "") + field,
                    keyword: "type"
                }];
        }
        return null;
    };
    return NumberArrayValidator;
}(ArrayValidator));
exports.NumberArrayValidator = NumberArrayValidator;
var RangeValidator = /** @class */ (function (_super) {
    __extends(RangeValidator, _super);
    function RangeValidator(minValue, maxValue) {
        var _this = _super.call(this) || this;
        _this.minValue = minValue;
        _this.maxValue = maxValue;
        return _this;
    }
    RangeValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        // input is a number, now check if it's in the given range
        if (input > this.maxValue || input < this.minValue) {
            return [{
                    message: field + " must be a number between " + this.minValue.toString() + " and " + this.maxValue.toString(),
                    path: (path ? path + "." : "") + field,
                    keyword: "range"
                }];
        }
        return null;
    };
    return RangeValidator;
}(NumberValidator));
exports.RangeValidator = RangeValidator;


/***/ }),
/* 5 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_77380__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.CaptureBookmarkRequestValidator = exports.CaptureBookmarkOptionsValidator = exports.ApplyBookmarkStateRequestValidator = exports.ApplyBookmarkByNameRequestValidator = exports.AddBookmarkRequestValidator = exports.PlayBookmarkRequestValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_77380__(3);
var typeValidator_1 = __nested_webpack_require_77380__(4);
var validator_1 = __nested_webpack_require_77380__(1);
var PlayBookmarkRequestValidator = /** @class */ (function (_super) {
    __extends(PlayBookmarkRequestValidator, _super);
    function PlayBookmarkRequestValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    PlayBookmarkRequestValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "playMode",
                validators: [validator_1.Validators.fieldRequiredValidator, new typeValidator_1.EnumValidator([0, 1])]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return PlayBookmarkRequestValidator;
}(typeValidator_1.ObjectValidator));
exports.PlayBookmarkRequestValidator = PlayBookmarkRequestValidator;
var AddBookmarkRequestValidator = /** @class */ (function (_super) {
    __extends(AddBookmarkRequestValidator, _super);
    function AddBookmarkRequestValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    AddBookmarkRequestValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "state",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "displayName",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "apply",
                validators: [validator_1.Validators.booleanValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return AddBookmarkRequestValidator;
}(typeValidator_1.ObjectValidator));
exports.AddBookmarkRequestValidator = AddBookmarkRequestValidator;
var ApplyBookmarkByNameRequestValidator = /** @class */ (function (_super) {
    __extends(ApplyBookmarkByNameRequestValidator, _super);
    function ApplyBookmarkByNameRequestValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ApplyBookmarkByNameRequestValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "name",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ApplyBookmarkByNameRequestValidator;
}(typeValidator_1.ObjectValidator));
exports.ApplyBookmarkByNameRequestValidator = ApplyBookmarkByNameRequestValidator;
var ApplyBookmarkStateRequestValidator = /** @class */ (function (_super) {
    __extends(ApplyBookmarkStateRequestValidator, _super);
    function ApplyBookmarkStateRequestValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ApplyBookmarkStateRequestValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "state",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ApplyBookmarkStateRequestValidator;
}(typeValidator_1.ObjectValidator));
exports.ApplyBookmarkStateRequestValidator = ApplyBookmarkStateRequestValidator;
var CaptureBookmarkOptionsValidator = /** @class */ (function (_super) {
    __extends(CaptureBookmarkOptionsValidator, _super);
    function CaptureBookmarkOptionsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    CaptureBookmarkOptionsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "personalizeVisuals",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "allPages",
                validators: [validator_1.Validators.booleanValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return CaptureBookmarkOptionsValidator;
}(typeValidator_1.ObjectValidator));
exports.CaptureBookmarkOptionsValidator = CaptureBookmarkOptionsValidator;
var CaptureBookmarkRequestValidator = /** @class */ (function (_super) {
    __extends(CaptureBookmarkRequestValidator, _super);
    function CaptureBookmarkRequestValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    CaptureBookmarkRequestValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "options",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.captureBookmarkOptionsValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return CaptureBookmarkRequestValidator;
}(typeValidator_1.ObjectValidator));
exports.CaptureBookmarkRequestValidator = CaptureBookmarkRequestValidator;


/***/ }),
/* 6 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_85856__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.PaginatedReportCommandsValidator = exports.SingleCommandSettingsValidator = exports.CommandsSettingsValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_85856__(3);
var typeValidator_1 = __nested_webpack_require_85856__(4);
var validator_1 = __nested_webpack_require_85856__(1);
var CommandsSettingsValidator = /** @class */ (function (_super) {
    __extends(CommandsSettingsValidator, _super);
    function CommandsSettingsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    CommandsSettingsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "copy",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "drill",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "drillthrough",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "expandCollapse",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "exportData",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "includeExclude",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "removeVisual",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "search",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "seeData",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "sort",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "spotlight",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "insightsAnalysis",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "addComment",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "groupVisualContainers",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "summarize",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            },
            {
                field: "clearSelection",
                validators: [validator_1.Validators.singleCommandSettingsValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return CommandsSettingsValidator;
}(typeValidator_1.ObjectValidator));
exports.CommandsSettingsValidator = CommandsSettingsValidator;
var SingleCommandSettingsValidator = /** @class */ (function (_super) {
    __extends(SingleCommandSettingsValidator, _super);
    function SingleCommandSettingsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    SingleCommandSettingsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "displayOption",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.commandDisplayOptionValidator]
            },
            {
                field: "selector",
                validators: [validator_1.Validators.visualCommandSelectorValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return SingleCommandSettingsValidator;
}(typeValidator_1.ObjectValidator));
exports.SingleCommandSettingsValidator = SingleCommandSettingsValidator;
var PaginatedReportCommandsValidator = /** @class */ (function (_super) {
    __extends(PaginatedReportCommandsValidator, _super);
    function PaginatedReportCommandsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    PaginatedReportCommandsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "parameterPanel",
                validators: [validator_1.Validators.parametersPanelValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return PaginatedReportCommandsValidator;
}(typeValidator_1.ObjectValidator));
exports.PaginatedReportCommandsValidator = PaginatedReportCommandsValidator;


/***/ }),
/* 7 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_92889__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.CustomThemeValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_92889__(3);
var typeValidator_1 = __nested_webpack_require_92889__(4);
var CustomThemeValidator = /** @class */ (function (_super) {
    __extends(CustomThemeValidator, _super);
    function CustomThemeValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    CustomThemeValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "themeJson",
                validators: [new typeValidator_1.ObjectValidator()]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return CustomThemeValidator;
}(typeValidator_1.ObjectValidator));
exports.CustomThemeValidator = CustomThemeValidator;


/***/ }),
/* 8 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_95043__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.DashboardLoadValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_95043__(3);
var typeValidator_1 = __nested_webpack_require_95043__(4);
var validator_1 = __nested_webpack_require_95043__(1);
var DashboardLoadValidator = /** @class */ (function (_super) {
    __extends(DashboardLoadValidator, _super);
    function DashboardLoadValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    DashboardLoadValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "accessToken",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "id",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "groupId",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "pageView",
                validators: [validator_1.Validators.pageViewFieldValidator]
            },
            {
                field: "tokenType",
                validators: [validator_1.Validators.tokenTypeValidator]
            },
            {
                field: "embedUrl",
                validators: [validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return DashboardLoadValidator;
}(typeValidator_1.ObjectValidator));
exports.DashboardLoadValidator = DashboardLoadValidator;


/***/ }),
/* 9 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_98042__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.DatasetBindingValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_98042__(3);
var typeValidator_1 = __nested_webpack_require_98042__(4);
var validator_1 = __nested_webpack_require_98042__(1);
var DatasetBindingValidator = /** @class */ (function (_super) {
    __extends(DatasetBindingValidator, _super);
    function DatasetBindingValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    DatasetBindingValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "datasetId",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return DatasetBindingValidator;
}(typeValidator_1.ObjectValidator));
exports.DatasetBindingValidator = DatasetBindingValidator;


/***/ }),
/* 10 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_100312__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.ExportDataRequestValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_100312__(3);
var typeValidator_1 = __nested_webpack_require_100312__(4);
var ExportDataRequestValidator = /** @class */ (function (_super) {
    __extends(ExportDataRequestValidator, _super);
    function ExportDataRequestValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ExportDataRequestValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "rows",
                validators: [new typeValidator_1.NumberValidator()]
            },
            {
                field: "exportDataType",
                validators: [new typeValidator_1.EnumValidator([0, 1])]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ExportDataRequestValidator;
}(typeValidator_1.ObjectValidator));
exports.ExportDataRequestValidator = ExportDataRequestValidator;


/***/ }),
/* 11 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_102656__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.ExtensionsValidator = exports.MenuGroupExtensionValidator = exports.ExtensionValidator = exports.CommandExtensionValidator = exports.ExtensionItemValidator = exports.ExtensionPointsValidator = exports.GroupedMenuExtensionValidator = exports.FlatMenuExtensionValidator = exports.MenuExtensionBaseValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_102656__(3);
var typeValidator_1 = __nested_webpack_require_102656__(4);
var validator_1 = __nested_webpack_require_102656__(1);
var MenuExtensionBaseValidator = /** @class */ (function (_super) {
    __extends(MenuExtensionBaseValidator, _super);
    function MenuExtensionBaseValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    MenuExtensionBaseValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "title",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "icon",
                validators: [validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return MenuExtensionBaseValidator;
}(typeValidator_1.ObjectValidator));
exports.MenuExtensionBaseValidator = MenuExtensionBaseValidator;
var FlatMenuExtensionValidator = /** @class */ (function (_super) {
    __extends(FlatMenuExtensionValidator, _super);
    function FlatMenuExtensionValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FlatMenuExtensionValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "menuLocation",
                validators: [validator_1.Validators.menuLocationValidator]
            },
            {
                field: "groupName",
                validators: [validator_1.Validators.fieldForbiddenValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return FlatMenuExtensionValidator;
}(MenuExtensionBaseValidator));
exports.FlatMenuExtensionValidator = FlatMenuExtensionValidator;
var GroupedMenuExtensionValidator = /** @class */ (function (_super) {
    __extends(GroupedMenuExtensionValidator, _super);
    function GroupedMenuExtensionValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    GroupedMenuExtensionValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "groupName",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "menuLocation",
                validators: [validator_1.Validators.fieldForbiddenValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return GroupedMenuExtensionValidator;
}(MenuExtensionBaseValidator));
exports.GroupedMenuExtensionValidator = GroupedMenuExtensionValidator;
var ExtensionPointsValidator = /** @class */ (function (_super) {
    __extends(ExtensionPointsValidator, _super);
    function ExtensionPointsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ExtensionPointsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "visualContextMenu",
                validators: [validator_1.Validators.menuExtensionValidator]
            },
            {
                field: "visualOptionsMenu",
                validators: [validator_1.Validators.menuExtensionValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ExtensionPointsValidator;
}(typeValidator_1.ObjectValidator));
exports.ExtensionPointsValidator = ExtensionPointsValidator;
var ExtensionItemValidator = /** @class */ (function (_super) {
    __extends(ExtensionItemValidator, _super);
    function ExtensionItemValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ExtensionItemValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "name",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "extend",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.extensionPointsValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ExtensionItemValidator;
}(typeValidator_1.ObjectValidator));
exports.ExtensionItemValidator = ExtensionItemValidator;
var CommandExtensionValidator = /** @class */ (function (_super) {
    __extends(CommandExtensionValidator, _super);
    function CommandExtensionValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    CommandExtensionValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "title",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "icon",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "selector",
                validators: [validator_1.Validators.commandExtensionSelectorValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return CommandExtensionValidator;
}(ExtensionItemValidator));
exports.CommandExtensionValidator = CommandExtensionValidator;
var ExtensionValidator = /** @class */ (function (_super) {
    __extends(ExtensionValidator, _super);
    function ExtensionValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ExtensionValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "command",
                validators: [validator_1.Validators.commandExtensionValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ExtensionValidator;
}(typeValidator_1.ObjectValidator));
exports.ExtensionValidator = ExtensionValidator;
var MenuGroupExtensionValidator = /** @class */ (function (_super) {
    __extends(MenuGroupExtensionValidator, _super);
    function MenuGroupExtensionValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    MenuGroupExtensionValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "name",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "title",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "menuLocation",
                validators: [validator_1.Validators.menuLocationValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return MenuGroupExtensionValidator;
}(typeValidator_1.ObjectValidator));
exports.MenuGroupExtensionValidator = MenuGroupExtensionValidator;
var ExtensionsValidator = /** @class */ (function (_super) {
    __extends(ExtensionsValidator, _super);
    function ExtensionsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ExtensionsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "commands",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.commandExtensionArrayValidator]
            },
            {
                field: "groups",
                validators: [validator_1.Validators.menuGroupExtensionArrayValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ExtensionsValidator;
}(typeValidator_1.ObjectValidator));
exports.ExtensionsValidator = ExtensionsValidator;


/***/ }),
/* 12 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_115147__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.OnLoadFiltersValidator = exports.OnLoadFiltersBaseRemoveOperationValidator = exports.OnLoadFiltersBaseValidator = exports.ConditionItemValidator = exports.RemoveFiltersRequestValidator = exports.UpdateFiltersRequestValidator = exports.FilterValidator = exports.HierarchyFilterNodeValidator = exports.HierarchyFilterValidator = exports.IncludeExcludeFilterValidator = exports.NotSupportedFilterValidator = exports.TopNFilterValidator = exports.RelativeTimeFilterValidator = exports.RelativeDateFilterValidator = exports.RelativeDateTimeFilterValidator = exports.AdvancedFilterValidator = exports.BasicFilterValidator = exports.FilterValidatorBase = exports.FilterDisplaySettingsValidator = exports.FilterMeasureTargetValidator = exports.FilterKeyHierarchyTargetValidator = exports.FilterHierarchyTargetValidator = exports.FilterKeyColumnsTargetValidator = exports.FilterColumnTargetValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_115147__(3);
var typeValidator_1 = __nested_webpack_require_115147__(4);
var validator_1 = __nested_webpack_require_115147__(1);
var FilterColumnTargetValidator = /** @class */ (function (_super) {
    __extends(FilterColumnTargetValidator, _super);
    function FilterColumnTargetValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FilterColumnTargetValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "table",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "column",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return FilterColumnTargetValidator;
}(typeValidator_1.ObjectValidator));
exports.FilterColumnTargetValidator = FilterColumnTargetValidator;
var FilterKeyColumnsTargetValidator = /** @class */ (function (_super) {
    __extends(FilterKeyColumnsTargetValidator, _super);
    function FilterKeyColumnsTargetValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FilterKeyColumnsTargetValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "keys",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringArrayValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return FilterKeyColumnsTargetValidator;
}(FilterColumnTargetValidator));
exports.FilterKeyColumnsTargetValidator = FilterKeyColumnsTargetValidator;
var FilterHierarchyTargetValidator = /** @class */ (function (_super) {
    __extends(FilterHierarchyTargetValidator, _super);
    function FilterHierarchyTargetValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FilterHierarchyTargetValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "table",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "hierarchy",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "hierarchyLevel",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return FilterHierarchyTargetValidator;
}(typeValidator_1.ObjectValidator));
exports.FilterHierarchyTargetValidator = FilterHierarchyTargetValidator;
var FilterKeyHierarchyTargetValidator = /** @class */ (function (_super) {
    __extends(FilterKeyHierarchyTargetValidator, _super);
    function FilterKeyHierarchyTargetValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FilterKeyHierarchyTargetValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "keys",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringArrayValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return FilterKeyHierarchyTargetValidator;
}(FilterHierarchyTargetValidator));
exports.FilterKeyHierarchyTargetValidator = FilterKeyHierarchyTargetValidator;
var FilterMeasureTargetValidator = /** @class */ (function (_super) {
    __extends(FilterMeasureTargetValidator, _super);
    function FilterMeasureTargetValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FilterMeasureTargetValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "table",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "measure",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return FilterMeasureTargetValidator;
}(typeValidator_1.ObjectValidator));
exports.FilterMeasureTargetValidator = FilterMeasureTargetValidator;
var FilterDisplaySettingsValidator = /** @class */ (function (_super) {
    __extends(FilterDisplaySettingsValidator, _super);
    function FilterDisplaySettingsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FilterDisplaySettingsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "isLockedInViewMode",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "isHiddenInViewMode",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "displayName",
                validators: [validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return FilterDisplaySettingsValidator;
}(typeValidator_1.ObjectValidator));
exports.FilterDisplaySettingsValidator = FilterDisplaySettingsValidator;
var FilterValidatorBase = /** @class */ (function (_super) {
    __extends(FilterValidatorBase, _super);
    function FilterValidatorBase() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FilterValidatorBase.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "target",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.filterTargetValidator]
            },
            {
                field: "$schema",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "filterType",
                validators: [validator_1.Validators.filterTypeValidator]
            },
            {
                field: "displaySettings",
                validators: [validator_1.Validators.filterDisplaySettingsValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return FilterValidatorBase;
}(typeValidator_1.ObjectValidator));
exports.FilterValidatorBase = FilterValidatorBase;
var BasicFilterValidator = /** @class */ (function (_super) {
    __extends(BasicFilterValidator, _super);
    function BasicFilterValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    BasicFilterValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "operator",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "values",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.anyArrayValidator]
            },
            {
                field: "filterType",
                validators: [validator_1.Validators.basicFilterTypeValidator]
            },
            {
                field: "requireSingleSelection",
                validators: [validator_1.Validators.booleanValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return BasicFilterValidator;
}(FilterValidatorBase));
exports.BasicFilterValidator = BasicFilterValidator;
var AdvancedFilterValidator = /** @class */ (function (_super) {
    __extends(AdvancedFilterValidator, _super);
    function AdvancedFilterValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    AdvancedFilterValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "logicalOperator",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "conditions",
                validators: [validator_1.Validators.filterConditionsValidator]
            },
            {
                field: "filterType",
                validators: [validator_1.Validators.advancedFilterTypeValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return AdvancedFilterValidator;
}(FilterValidatorBase));
exports.AdvancedFilterValidator = AdvancedFilterValidator;
var RelativeDateTimeFilterValidator = /** @class */ (function (_super) {
    __extends(RelativeDateTimeFilterValidator, _super);
    function RelativeDateTimeFilterValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    RelativeDateTimeFilterValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "operator",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.relativeDateFilterOperatorValidator]
            },
            {
                field: "timeUnitsCount",
                validators: [validator_1.Validators.numberValidator]
            },
            {
                field: "timeUnitType",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.relativeDateTimeFilterUnitTypeValidator]
            },
            {
                field: "filterType",
                validators: [validator_1.Validators.relativeDateTimeFilterTypeValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return RelativeDateTimeFilterValidator;
}(FilterValidatorBase));
exports.RelativeDateTimeFilterValidator = RelativeDateTimeFilterValidator;
var RelativeDateFilterValidator = /** @class */ (function (_super) {
    __extends(RelativeDateFilterValidator, _super);
    function RelativeDateFilterValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    RelativeDateFilterValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "includeToday",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.booleanValidator]
            },
            {
                field: "timeUnitType",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.relativeDateFilterTimeUnitTypeValidator]
            },
            {
                field: "filterType",
                validators: [validator_1.Validators.relativeDateFilterTypeValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return RelativeDateFilterValidator;
}(RelativeDateTimeFilterValidator));
exports.RelativeDateFilterValidator = RelativeDateFilterValidator;
var RelativeTimeFilterValidator = /** @class */ (function (_super) {
    __extends(RelativeTimeFilterValidator, _super);
    function RelativeTimeFilterValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    RelativeTimeFilterValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "timeUnitType",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.relativeTimeFilterTimeUnitTypeValidator]
            },
            {
                field: "filterType",
                validators: [validator_1.Validators.relativeTimeFilterTypeValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return RelativeTimeFilterValidator;
}(RelativeDateTimeFilterValidator));
exports.RelativeTimeFilterValidator = RelativeTimeFilterValidator;
var TopNFilterValidator = /** @class */ (function (_super) {
    __extends(TopNFilterValidator, _super);
    function TopNFilterValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    TopNFilterValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "operator",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "itemCount",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.numberValidator]
            },
            {
                field: "filterType",
                validators: [validator_1.Validators.topNFilterTypeValidator]
            },
            {
                field: "orderBy",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.filterTargetValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return TopNFilterValidator;
}(FilterValidatorBase));
exports.TopNFilterValidator = TopNFilterValidator;
var NotSupportedFilterValidator = /** @class */ (function (_super) {
    __extends(NotSupportedFilterValidator, _super);
    function NotSupportedFilterValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    NotSupportedFilterValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "message",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "notSupportedTypeName",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "filterType",
                validators: [validator_1.Validators.notSupportedFilterTypeValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return NotSupportedFilterValidator;
}(FilterValidatorBase));
exports.NotSupportedFilterValidator = NotSupportedFilterValidator;
var IncludeExcludeFilterValidator = /** @class */ (function (_super) {
    __extends(IncludeExcludeFilterValidator, _super);
    function IncludeExcludeFilterValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    IncludeExcludeFilterValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "isExclude",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.booleanValidator]
            },
            {
                field: "values",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.anyArrayValidator]
            },
            {
                field: "filterType",
                validators: [validator_1.Validators.includeExludeFilterTypeValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return IncludeExcludeFilterValidator;
}(FilterValidatorBase));
exports.IncludeExcludeFilterValidator = IncludeExcludeFilterValidator;
var HierarchyFilterValidator = /** @class */ (function (_super) {
    __extends(HierarchyFilterValidator, _super);
    function HierarchyFilterValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    HierarchyFilterValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "hierarchyData",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.hierarchyFilterValuesValidator]
            },
            {
                field: "filterType",
                validators: [validator_1.Validators.hierarchyFilterTypeValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return HierarchyFilterValidator;
}(FilterValidatorBase));
exports.HierarchyFilterValidator = HierarchyFilterValidator;
var HierarchyFilterNodeValidator = /** @class */ (function (_super) {
    __extends(HierarchyFilterNodeValidator, _super);
    function HierarchyFilterNodeValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    HierarchyFilterNodeValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "value",
                validators: [validator_1.Validators.anyValueValidator]
            },
            {
                field: "keyValues",
                validators: [validator_1.Validators.anyArrayValidator]
            },
            {
                field: "children",
                validators: [validator_1.Validators.hierarchyFilterValuesValidator]
            },
            {
                field: "operator",
                validators: [validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return HierarchyFilterNodeValidator;
}(typeValidator_1.ObjectValidator));
exports.HierarchyFilterNodeValidator = HierarchyFilterNodeValidator;
var FilterValidator = /** @class */ (function (_super) {
    __extends(FilterValidator, _super);
    function FilterValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FilterValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        return validator_1.Validators.anyFilterValidator.validate(input, path, field);
    };
    return FilterValidator;
}(typeValidator_1.ObjectValidator));
exports.FilterValidator = FilterValidator;
var UpdateFiltersRequestValidator = /** @class */ (function (_super) {
    __extends(UpdateFiltersRequestValidator, _super);
    function UpdateFiltersRequestValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    UpdateFiltersRequestValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "filtersOperation",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.filtersOperationsUpdateValidator]
            },
            {
                field: "filters",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.filtersArrayValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return UpdateFiltersRequestValidator;
}(typeValidator_1.ObjectValidator));
exports.UpdateFiltersRequestValidator = UpdateFiltersRequestValidator;
var RemoveFiltersRequestValidator = /** @class */ (function (_super) {
    __extends(RemoveFiltersRequestValidator, _super);
    function RemoveFiltersRequestValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    RemoveFiltersRequestValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "filtersOperation",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.filtersOperationsRemoveAllValidator]
            },
            {
                field: "filters",
                validators: [validator_1.Validators.fieldForbiddenValidator, validator_1.Validators.filtersArrayValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return RemoveFiltersRequestValidator;
}(typeValidator_1.ObjectValidator));
exports.RemoveFiltersRequestValidator = RemoveFiltersRequestValidator;
var ConditionItemValidator = /** @class */ (function (_super) {
    __extends(ConditionItemValidator, _super);
    function ConditionItemValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ConditionItemValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "value",
                validators: [validator_1.Validators.anyValueValidator]
            },
            {
                field: "operator",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ConditionItemValidator;
}(typeValidator_1.ObjectValidator));
exports.ConditionItemValidator = ConditionItemValidator;
var OnLoadFiltersBaseValidator = /** @class */ (function (_super) {
    __extends(OnLoadFiltersBaseValidator, _super);
    function OnLoadFiltersBaseValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    OnLoadFiltersBaseValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "operation",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.filtersOperationsUpdateValidator]
            },
            {
                field: "filters",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.filtersArrayValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return OnLoadFiltersBaseValidator;
}(typeValidator_1.ObjectValidator));
exports.OnLoadFiltersBaseValidator = OnLoadFiltersBaseValidator;
var OnLoadFiltersBaseRemoveOperationValidator = /** @class */ (function (_super) {
    __extends(OnLoadFiltersBaseRemoveOperationValidator, _super);
    function OnLoadFiltersBaseRemoveOperationValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    OnLoadFiltersBaseRemoveOperationValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "operation",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.filtersOperationsRemoveAllValidator]
            },
            {
                field: "filters",
                validators: [validator_1.Validators.fieldForbiddenValidator, validator_1.Validators.filtersArrayValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return OnLoadFiltersBaseRemoveOperationValidator;
}(typeValidator_1.ObjectValidator));
exports.OnLoadFiltersBaseRemoveOperationValidator = OnLoadFiltersBaseRemoveOperationValidator;
var OnLoadFiltersValidator = /** @class */ (function (_super) {
    __extends(OnLoadFiltersValidator, _super);
    function OnLoadFiltersValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    OnLoadFiltersValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "allPages",
                validators: [validator_1.Validators.onLoadFiltersBaseValidator]
            },
            {
                field: "currentPage",
                validators: [validator_1.Validators.onLoadFiltersBaseValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return OnLoadFiltersValidator;
}(typeValidator_1.ObjectValidator));
exports.OnLoadFiltersValidator = OnLoadFiltersValidator;


/***/ }),
/* 13 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_149119__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.PageLayoutValidator = exports.DisplayStateValidator = exports.VisualLayoutValidator = exports.CustomLayoutValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_149119__(3);
var typeValidator_1 = __nested_webpack_require_149119__(4);
var validator_1 = __nested_webpack_require_149119__(1);
var CustomLayoutValidator = /** @class */ (function (_super) {
    __extends(CustomLayoutValidator, _super);
    function CustomLayoutValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    CustomLayoutValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "pageSize",
                validators: [validator_1.Validators.pageSizeValidator]
            },
            {
                field: "displayOption",
                validators: [validator_1.Validators.customLayoutDisplayOptionValidator]
            },
            {
                field: "pagesLayout",
                validators: [validator_1.Validators.pagesLayoutValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return CustomLayoutValidator;
}(typeValidator_1.ObjectValidator));
exports.CustomLayoutValidator = CustomLayoutValidator;
var VisualLayoutValidator = /** @class */ (function (_super) {
    __extends(VisualLayoutValidator, _super);
    function VisualLayoutValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    VisualLayoutValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "x",
                validators: [validator_1.Validators.numberValidator]
            },
            {
                field: "y",
                validators: [validator_1.Validators.numberValidator]
            },
            {
                field: "z",
                validators: [validator_1.Validators.numberValidator]
            },
            {
                field: "width",
                validators: [validator_1.Validators.numberValidator]
            },
            {
                field: "height",
                validators: [validator_1.Validators.numberValidator]
            },
            {
                field: "displayState",
                validators: [validator_1.Validators.displayStateValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return VisualLayoutValidator;
}(typeValidator_1.ObjectValidator));
exports.VisualLayoutValidator = VisualLayoutValidator;
var DisplayStateValidator = /** @class */ (function (_super) {
    __extends(DisplayStateValidator, _super);
    function DisplayStateValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    DisplayStateValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "mode",
                validators: [validator_1.Validators.displayStateModeValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return DisplayStateValidator;
}(typeValidator_1.ObjectValidator));
exports.DisplayStateValidator = DisplayStateValidator;
var PageLayoutValidator = /** @class */ (function (_super) {
    __extends(PageLayoutValidator, _super);
    function PageLayoutValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    PageLayoutValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "visualsLayout",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.pageLayoutValidator]
            },
            {
                field: "defaultLayout",
                validators: [validator_1.Validators.visualLayoutValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return PageLayoutValidator;
}(typeValidator_1.ObjectValidator));
exports.PageLayoutValidator = PageLayoutValidator;


/***/ }),
/* 14 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_155598__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.PageViewFieldValidator = exports.PageValidator = exports.CustomPageSizeValidator = exports.PageSizeValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_155598__(3);
var typeValidator_1 = __nested_webpack_require_155598__(4);
var validator_1 = __nested_webpack_require_155598__(1);
var PageSizeValidator = /** @class */ (function (_super) {
    __extends(PageSizeValidator, _super);
    function PageSizeValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    PageSizeValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "type",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.pageSizeTypeValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return PageSizeValidator;
}(typeValidator_1.ObjectValidator));
exports.PageSizeValidator = PageSizeValidator;
var CustomPageSizeValidator = /** @class */ (function (_super) {
    __extends(CustomPageSizeValidator, _super);
    function CustomPageSizeValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    CustomPageSizeValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "width",
                validators: [validator_1.Validators.numberValidator]
            },
            {
                field: "height",
                validators: [validator_1.Validators.numberValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return CustomPageSizeValidator;
}(PageSizeValidator));
exports.CustomPageSizeValidator = CustomPageSizeValidator;
var PageValidator = /** @class */ (function (_super) {
    __extends(PageValidator, _super);
    function PageValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    PageValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "name",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return PageValidator;
}(typeValidator_1.ObjectValidator));
exports.PageValidator = PageValidator;
var PageViewFieldValidator = /** @class */ (function (_super) {
    __extends(PageViewFieldValidator, _super);
    function PageViewFieldValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    PageViewFieldValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var possibleValues = ["actualSize", "fitToWidth", "oneColumn"];
        if (possibleValues.indexOf(input) < 0) {
            return [{
                    message: "pageView must be a string with one of the following values: \"actualSize\", \"fitToWidth\", \"oneColumn\""
                }];
        }
        return null;
    };
    return PageViewFieldValidator;
}(typeValidator_1.StringValidator));
exports.PageViewFieldValidator = PageViewFieldValidator;


/***/ }),
/* 15 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_161038__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.VisualizationsPaneValidator = exports.SyncSlicersPaneValidator = exports.SelectionPaneValidator = exports.PageNavigationPaneValidator = exports.FiltersPaneValidator = exports.FieldsPaneValidator = exports.BookmarksPaneValidator = exports.QnaPanesValidator = exports.ReportPanesValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_161038__(3);
var typeValidator_1 = __nested_webpack_require_161038__(4);
var validator_1 = __nested_webpack_require_161038__(1);
var ReportPanesValidator = /** @class */ (function (_super) {
    __extends(ReportPanesValidator, _super);
    function ReportPanesValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ReportPanesValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "bookmarks",
                validators: [validator_1.Validators.bookmarksPaneValidator]
            },
            {
                field: "fields",
                validators: [validator_1.Validators.fieldsPaneValidator]
            },
            {
                field: "filters",
                validators: [validator_1.Validators.filtersPaneValidator]
            },
            {
                field: "pageNavigation",
                validators: [validator_1.Validators.pageNavigationPaneValidator]
            },
            {
                field: "selection",
                validators: [validator_1.Validators.selectionPaneValidator]
            },
            {
                field: "syncSlicers",
                validators: [validator_1.Validators.syncSlicersPaneValidator]
            },
            {
                field: "visualizations",
                validators: [validator_1.Validators.visualizationsPaneValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ReportPanesValidator;
}(typeValidator_1.ObjectValidator));
exports.ReportPanesValidator = ReportPanesValidator;
var QnaPanesValidator = /** @class */ (function (_super) {
    __extends(QnaPanesValidator, _super);
    function QnaPanesValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    QnaPanesValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "filters",
                validators: [validator_1.Validators.filtersPaneValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return QnaPanesValidator;
}(typeValidator_1.ObjectValidator));
exports.QnaPanesValidator = QnaPanesValidator;
var BookmarksPaneValidator = /** @class */ (function (_super) {
    __extends(BookmarksPaneValidator, _super);
    function BookmarksPaneValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    BookmarksPaneValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "visible",
                validators: [validator_1.Validators.booleanValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return BookmarksPaneValidator;
}(typeValidator_1.ObjectValidator));
exports.BookmarksPaneValidator = BookmarksPaneValidator;
var FieldsPaneValidator = /** @class */ (function (_super) {
    __extends(FieldsPaneValidator, _super);
    function FieldsPaneValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FieldsPaneValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "expanded",
                validators: [validator_1.Validators.booleanValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return FieldsPaneValidator;
}(typeValidator_1.ObjectValidator));
exports.FieldsPaneValidator = FieldsPaneValidator;
var FiltersPaneValidator = /** @class */ (function (_super) {
    __extends(FiltersPaneValidator, _super);
    function FiltersPaneValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FiltersPaneValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "visible",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "expanded",
                validators: [validator_1.Validators.booleanValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return FiltersPaneValidator;
}(typeValidator_1.ObjectValidator));
exports.FiltersPaneValidator = FiltersPaneValidator;
var PageNavigationPaneValidator = /** @class */ (function (_super) {
    __extends(PageNavigationPaneValidator, _super);
    function PageNavigationPaneValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    PageNavigationPaneValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "visible",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "position",
                validators: [validator_1.Validators.pageNavigationPositionValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return PageNavigationPaneValidator;
}(typeValidator_1.ObjectValidator));
exports.PageNavigationPaneValidator = PageNavigationPaneValidator;
var SelectionPaneValidator = /** @class */ (function (_super) {
    __extends(SelectionPaneValidator, _super);
    function SelectionPaneValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    SelectionPaneValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "visible",
                validators: [validator_1.Validators.booleanValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return SelectionPaneValidator;
}(typeValidator_1.ObjectValidator));
exports.SelectionPaneValidator = SelectionPaneValidator;
var SyncSlicersPaneValidator = /** @class */ (function (_super) {
    __extends(SyncSlicersPaneValidator, _super);
    function SyncSlicersPaneValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    SyncSlicersPaneValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "visible",
                validators: [validator_1.Validators.booleanValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return SyncSlicersPaneValidator;
}(typeValidator_1.ObjectValidator));
exports.SyncSlicersPaneValidator = SyncSlicersPaneValidator;
var VisualizationsPaneValidator = /** @class */ (function (_super) {
    __extends(VisualizationsPaneValidator, _super);
    function VisualizationsPaneValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    VisualizationsPaneValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "expanded",
                validators: [validator_1.Validators.booleanValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return VisualizationsPaneValidator;
}(typeValidator_1.ObjectValidator));
exports.VisualizationsPaneValidator = VisualizationsPaneValidator;


/***/ }),
/* 16 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_172784__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.QnaInterpretInputDataValidator = exports.QnaSettingsValidator = exports.LoadQnaValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_172784__(3);
var typeValidator_1 = __nested_webpack_require_172784__(4);
var validator_1 = __nested_webpack_require_172784__(1);
var LoadQnaValidator = /** @class */ (function (_super) {
    __extends(LoadQnaValidator, _super);
    function LoadQnaValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    LoadQnaValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "accessToken",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "datasetIds",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringArrayValidator]
            },
            {
                field: "question",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "viewMode",
                validators: [validator_1.Validators.viewModeValidator]
            },
            {
                field: "settings",
                validators: [validator_1.Validators.qnaSettingValidator]
            },
            {
                field: "tokenType",
                validators: [validator_1.Validators.tokenTypeValidator]
            },
            {
                field: "groupId",
                validators: [validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return LoadQnaValidator;
}(typeValidator_1.ObjectValidator));
exports.LoadQnaValidator = LoadQnaValidator;
var QnaSettingsValidator = /** @class */ (function (_super) {
    __extends(QnaSettingsValidator, _super);
    function QnaSettingsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    QnaSettingsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "filterPaneEnabled",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "hideErrors",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "panes",
                validators: [validator_1.Validators.qnaPanesValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return QnaSettingsValidator;
}(typeValidator_1.ObjectValidator));
exports.QnaSettingsValidator = QnaSettingsValidator;
var QnaInterpretInputDataValidator = /** @class */ (function (_super) {
    __extends(QnaInterpretInputDataValidator, _super);
    function QnaInterpretInputDataValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    QnaInterpretInputDataValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "datasetIds",
                validators: [validator_1.Validators.stringArrayValidator]
            },
            {
                field: "question",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return QnaInterpretInputDataValidator;
}(typeValidator_1.ObjectValidator));
exports.QnaInterpretInputDataValidator = QnaInterpretInputDataValidator;


/***/ }),
/* 17 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_178495__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.ReportCreateValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_178495__(3);
var typeValidator_1 = __nested_webpack_require_178495__(4);
var validator_1 = __nested_webpack_require_178495__(1);
var ReportCreateValidator = /** @class */ (function (_super) {
    __extends(ReportCreateValidator, _super);
    function ReportCreateValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ReportCreateValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "accessToken",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "datasetId",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "groupId",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "tokenType",
                validators: [validator_1.Validators.tokenTypeValidator]
            },
            {
                field: "theme",
                validators: [validator_1.Validators.customThemeValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ReportCreateValidator;
}(typeValidator_1.ObjectValidator));
exports.ReportCreateValidator = ReportCreateValidator;


/***/ }),
/* 18 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_181353__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.ReportLoadValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_181353__(3);
var typeValidator_1 = __nested_webpack_require_181353__(4);
var validator_1 = __nested_webpack_require_181353__(1);
var ReportLoadValidator = /** @class */ (function (_super) {
    __extends(ReportLoadValidator, _super);
    function ReportLoadValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ReportLoadValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "accessToken",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "id",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "groupId",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "settings",
                validators: [validator_1.Validators.settingsValidator]
            },
            {
                field: "pageName",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "filters",
                validators: [validator_1.Validators.reportLoadFiltersValidator]
            },
            {
                field: "permissions",
                validators: [validator_1.Validators.permissionsValidator]
            },
            {
                field: "viewMode",
                validators: [validator_1.Validators.viewModeValidator]
            },
            {
                field: "tokenType",
                validators: [validator_1.Validators.tokenTypeValidator]
            },
            {
                field: "bookmark",
                validators: [validator_1.Validators.applyBookmarkValidator]
            },
            {
                field: "theme",
                validators: [validator_1.Validators.customThemeValidator]
            },
            {
                field: "embedUrl",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "datasetBinding",
                validators: [validator_1.Validators.datasetBindingValidator]
            },
            {
                field: "contrastMode",
                validators: [validator_1.Validators.contrastModeValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ReportLoadValidator;
}(typeValidator_1.ObjectValidator));
exports.ReportLoadValidator = ReportLoadValidator;


/***/ }),
/* 19 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_185474__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.ReportParameterFieldsValidator = exports.PaginatedReportLoadValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_185474__(3);
var typeValidator_1 = __nested_webpack_require_185474__(4);
var validator_1 = __nested_webpack_require_185474__(1);
var PaginatedReportLoadValidator = /** @class */ (function (_super) {
    __extends(PaginatedReportLoadValidator, _super);
    function PaginatedReportLoadValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    PaginatedReportLoadValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "accessToken",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "id",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "groupId",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "settings",
                validators: [validator_1.Validators.paginatedReportsettingsValidator]
            },
            {
                field: "tokenType",
                validators: [validator_1.Validators.tokenTypeValidator]
            },
            {
                field: "embedUrl",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "type",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "parameterValues",
                validators: [validator_1.Validators.parameterValuesArrayValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return PaginatedReportLoadValidator;
}(typeValidator_1.ObjectValidator));
exports.PaginatedReportLoadValidator = PaginatedReportLoadValidator;
var ReportParameterFieldsValidator = /** @class */ (function () {
    function ReportParameterFieldsValidator() {
    }
    ReportParameterFieldsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var fields = [
            {
                field: "name",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "value",
                validators: [validator_1.Validators.stringValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ReportParameterFieldsValidator;
}());
exports.ReportParameterFieldsValidator = ReportParameterFieldsValidator;


/***/ }),
/* 20 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_189798__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.SaveAsParametersValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_189798__(3);
var typeValidator_1 = __nested_webpack_require_189798__(4);
var validator_1 = __nested_webpack_require_189798__(1);
var SaveAsParametersValidator = /** @class */ (function (_super) {
    __extends(SaveAsParametersValidator, _super);
    function SaveAsParametersValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    SaveAsParametersValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "name",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return SaveAsParametersValidator;
}(typeValidator_1.ObjectValidator));
exports.SaveAsParametersValidator = SaveAsParametersValidator;


/***/ }),
/* 21 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_192079__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.SlicerTargetSelectorValidator = exports.VisualTypeSelectorValidator = exports.VisualSelectorValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_192079__(3);
var typeValidator_1 = __nested_webpack_require_192079__(4);
var typeValidator_2 = __nested_webpack_require_192079__(4);
var validator_1 = __nested_webpack_require_192079__(1);
var VisualSelectorValidator = /** @class */ (function (_super) {
    __extends(VisualSelectorValidator, _super);
    function VisualSelectorValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    VisualSelectorValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                // Not required for this selector only - Backward compatibility
                field: "$schema",
                validators: [validator_1.Validators.stringValidator, new typeValidator_2.SchemaValidator("http://powerbi.com/product/schema#visualSelector")]
            },
            {
                field: "visualName",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return VisualSelectorValidator;
}(typeValidator_1.ObjectValidator));
exports.VisualSelectorValidator = VisualSelectorValidator;
var VisualTypeSelectorValidator = /** @class */ (function (_super) {
    __extends(VisualTypeSelectorValidator, _super);
    function VisualTypeSelectorValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    VisualTypeSelectorValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "$schema",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator, new typeValidator_2.SchemaValidator("http://powerbi.com/product/schema#visualTypeSelector")]
            },
            {
                field: "visualType",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return VisualTypeSelectorValidator;
}(typeValidator_1.ObjectValidator));
exports.VisualTypeSelectorValidator = VisualTypeSelectorValidator;
var SlicerTargetSelectorValidator = /** @class */ (function (_super) {
    __extends(SlicerTargetSelectorValidator, _super);
    function SlicerTargetSelectorValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    SlicerTargetSelectorValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "$schema",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator, new typeValidator_2.SchemaValidator("http://powerbi.com/product/schema#slicerTargetSelector")]
            },
            {
                field: "target",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.slicerTargetValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return SlicerTargetSelectorValidator;
}(typeValidator_1.ObjectValidator));
exports.SlicerTargetSelectorValidator = SlicerTargetSelectorValidator;


/***/ }),
/* 22 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_197537__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.PaginatedReportSettingsValidator = exports.SettingsValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_197537__(3);
var typeValidator_1 = __nested_webpack_require_197537__(4);
var validator_1 = __nested_webpack_require_197537__(1);
var SettingsValidator = /** @class */ (function (_super) {
    __extends(SettingsValidator, _super);
    function SettingsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    SettingsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "filterPaneEnabled",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "navContentPaneEnabled",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "bookmarksPaneEnabled",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "useCustomSaveAsDialog",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "extensions",
                validators: [validator_1.Validators.extensionsValidator]
            },
            {
                field: "layoutType",
                validators: [validator_1.Validators.layoutTypeValidator]
            },
            {
                field: "customLayout",
                validators: [validator_1.Validators.customLayoutValidator]
            },
            {
                field: "background",
                validators: [validator_1.Validators.backgroundValidator]
            },
            {
                field: "visualSettings",
                validators: [validator_1.Validators.visualSettingsValidator]
            },
            {
                field: "hideErrors",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "commands",
                validators: [validator_1.Validators.commandsSettingsArrayValidator]
            },
            {
                field: "hyperlinkClickBehavior",
                validators: [validator_1.Validators.hyperlinkClickBehaviorValidator]
            },
            {
                field: "bars",
                validators: [validator_1.Validators.reportBarsValidator]
            },
            {
                field: "panes",
                validators: [validator_1.Validators.reportPanesValidator]
            },
            {
                field: "personalBookmarksEnabled",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "persistentFiltersEnabled",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "visualRenderedEvents",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "authoringHintsEnabled",
                validators: [validator_1.Validators.booleanValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return SettingsValidator;
}(typeValidator_1.ObjectValidator));
exports.SettingsValidator = SettingsValidator;
var PaginatedReportSettingsValidator = /** @class */ (function (_super) {
    __extends(PaginatedReportSettingsValidator, _super);
    function PaginatedReportSettingsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    PaginatedReportSettingsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "commands",
                validators: [validator_1.Validators.paginatedReportCommandsValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return PaginatedReportSettingsValidator;
}(typeValidator_1.ObjectValidator));
exports.PaginatedReportSettingsValidator = PaginatedReportSettingsValidator;


/***/ }),
/* 23 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_203384__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.SlicerStateValidator = exports.SlicerValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_203384__(3);
var typeValidator_1 = __nested_webpack_require_203384__(4);
var validator_1 = __nested_webpack_require_203384__(1);
var SlicerValidator = /** @class */ (function (_super) {
    __extends(SlicerValidator, _super);
    function SlicerValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    SlicerValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "selector",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.slicerSelectorValidator]
            },
            {
                field: "state",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.slicerStateValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return SlicerValidator;
}(typeValidator_1.ObjectValidator));
exports.SlicerValidator = SlicerValidator;
var SlicerStateValidator = /** @class */ (function (_super) {
    __extends(SlicerStateValidator, _super);
    function SlicerStateValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    SlicerStateValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "filters",
                validators: [validator_1.Validators.filtersArrayValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return SlicerStateValidator;
}(typeValidator_1.ObjectValidator));
exports.SlicerStateValidator = SlicerStateValidator;


/***/ }),
/* 24 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_206814__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.TileLoadValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_206814__(3);
var typeValidator_1 = __nested_webpack_require_206814__(4);
var validator_1 = __nested_webpack_require_206814__(1);
var TileLoadValidator = /** @class */ (function (_super) {
    __extends(TileLoadValidator, _super);
    function TileLoadValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    TileLoadValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "accessToken",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "id",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "dashboardId",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "groupId",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "pageView",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "tokenType",
                validators: [validator_1.Validators.tokenTypeValidator]
            },
            {
                field: "width",
                validators: [validator_1.Validators.numberValidator]
            },
            {
                field: "height",
                validators: [validator_1.Validators.numberValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return TileLoadValidator;
}(typeValidator_1.ObjectValidator));
exports.TileLoadValidator = TileLoadValidator;


/***/ }),
/* 25 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_210086__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.VisualHeaderValidator = exports.VisualHeaderSettingsValidator = exports.VisualSettingsValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_210086__(3);
var typeValidator_1 = __nested_webpack_require_210086__(4);
var validator_1 = __nested_webpack_require_210086__(1);
var VisualSettingsValidator = /** @class */ (function (_super) {
    __extends(VisualSettingsValidator, _super);
    function VisualSettingsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    VisualSettingsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "visualHeaders",
                validators: [validator_1.Validators.visualHeadersValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return VisualSettingsValidator;
}(typeValidator_1.ObjectValidator));
exports.VisualSettingsValidator = VisualSettingsValidator;
var VisualHeaderSettingsValidator = /** @class */ (function (_super) {
    __extends(VisualHeaderSettingsValidator, _super);
    function VisualHeaderSettingsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    VisualHeaderSettingsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "visible",
                validators: [validator_1.Validators.booleanValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return VisualHeaderSettingsValidator;
}(typeValidator_1.ObjectValidator));
exports.VisualHeaderSettingsValidator = VisualHeaderSettingsValidator;
var VisualHeaderValidator = /** @class */ (function (_super) {
    __extends(VisualHeaderValidator, _super);
    function VisualHeaderValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    VisualHeaderValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "settings",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.visualHeaderSettingsValidator]
            },
            {
                field: "selector",
                validators: [validator_1.Validators.visualHeaderSelectorValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return VisualHeaderValidator;
}(typeValidator_1.ObjectValidator));
exports.VisualHeaderValidator = VisualHeaderValidator;


/***/ }),
/* 26 */
/***/ ((__unused_webpack_module, exports) => {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.AnyOfValidator = void 0;
var AnyOfValidator = /** @class */ (function () {
    function AnyOfValidator(validators) {
        this.validators = validators;
    }
    AnyOfValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var valid = false;
        for (var _i = 0, _a = this.validators; _i < _a.length; _i++) {
            var validator = _a[_i];
            var errors = validator.validate(input, path, field);
            if (!errors) {
                valid = true;
                break;
            }
        }
        if (!valid) {
            return [{
                    message: field + " property is invalid",
                    path: (path ? path + "." : "") + field,
                    keyword: "invalid"
                }];
        }
        return null;
    };
    return AnyOfValidator;
}());
exports.AnyOfValidator = AnyOfValidator;


/***/ }),
/* 27 */
/***/ ((__unused_webpack_module, exports) => {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.FieldForbiddenValidator = void 0;
var FieldForbiddenValidator = /** @class */ (function () {
    function FieldForbiddenValidator() {
    }
    FieldForbiddenValidator.prototype.validate = function (input, path, field) {
        if (input !== undefined) {
            return [{
                    message: field + " is forbidden",
                    path: (path ? path + "." : "") + field,
                    keyword: "forbidden"
                }];
        }
        return null;
    };
    return FieldForbiddenValidator;
}());
exports.FieldForbiddenValidator = FieldForbiddenValidator;


/***/ }),
/* 28 */
/***/ ((__unused_webpack_module, exports) => {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.FieldRequiredValidator = void 0;
var FieldRequiredValidator = /** @class */ (function () {
    function FieldRequiredValidator() {
    }
    FieldRequiredValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return [{
                    message: field + " is required",
                    path: (path ? path + "." : "") + field,
                    keyword: "required"
                }];
        }
        return null;
    };
    return FieldRequiredValidator;
}());
exports.FieldRequiredValidator = FieldRequiredValidator;


/***/ }),
/* 29 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_217495__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.MapValidator = void 0;
var typeValidator_1 = __nested_webpack_require_217495__(4);
var MapValidator = /** @class */ (function (_super) {
    __extends(MapValidator, _super);
    function MapValidator(keyValidators, valueValidators) {
        var _this = _super.call(this) || this;
        _this.keyValidators = keyValidators;
        _this.valueValidators = valueValidators;
        return _this;
    }
    MapValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        for (var key in input) {
            if (input.hasOwnProperty(key)) {
                var fieldsPath = (path ? path + "." : "") + field + "." + key;
                for (var _i = 0, _a = this.keyValidators; _i < _a.length; _i++) {
                    var keyValidator = _a[_i];
                    errors = keyValidator.validate(key, fieldsPath, field);
                    if (errors) {
                        return errors;
                    }
                }
                for (var _b = 0, _c = this.valueValidators; _b < _c.length; _b++) {
                    var valueValidator = _c[_b];
                    errors = valueValidator.validate(input[key], fieldsPath, field);
                    if (errors) {
                        return errors;
                    }
                }
            }
        }
        return null;
    };
    return MapValidator;
}(typeValidator_1.ObjectValidator));
exports.MapValidator = MapValidator;


/***/ }),
/* 30 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_220179__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.ParametersPanelValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_220179__(3);
var typeValidator_1 = __nested_webpack_require_220179__(4);
var validator_1 = __nested_webpack_require_220179__(1);
var ParametersPanelValidator = /** @class */ (function (_super) {
    __extends(ParametersPanelValidator, _super);
    function ParametersPanelValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ParametersPanelValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "expanded",
                validators: [validator_1.Validators.booleanValidator]
            },
            {
                field: "enabled",
                validators: [validator_1.Validators.booleanValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ParametersPanelValidator;
}(typeValidator_1.ObjectValidator));
exports.ParametersPanelValidator = ParametersPanelValidator;


/***/ }),
/* 31 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_222547__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.TableDataValidator = exports.TableSchemaValidator = exports.ColumnSchemaValidator = exports.CredentialsValidator = exports.DatasourceConnectionConfigValidator = exports.DatasetCreateConfigValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_222547__(3);
var typeValidator_1 = __nested_webpack_require_222547__(4);
var validator_1 = __nested_webpack_require_222547__(1);
var DatasetCreateConfigValidator = /** @class */ (function (_super) {
    __extends(DatasetCreateConfigValidator, _super);
    function DatasetCreateConfigValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    DatasetCreateConfigValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "locale",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "mashupDocument",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "datasourceConnectionConfig",
                validators: [validator_1.Validators.datasourceConnectionConfigValidator]
            },
            {
                field: "tableSchemaList",
                validators: [validator_1.Validators.tableSchemaListValidator]
            },
            {
                field: "data",
                validators: [validator_1.Validators.tableDataArrayValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        errors = multipleFieldsValidator.validate(input, path, field);
        if (errors) {
            return errors;
        }
        if (input["datasourceConnectionConfig"] && input["mashupDocument"] == null) {
            return [{
                    message: "mashupDocument cannot be empty when datasourceConnectionConfig is presented"
                }];
        }
        if (input["data"] && input["tableSchemaList"] == null) {
            return [{
                    message: "tableSchemaList cannot be empty when data is provided"
                }];
        }
        if (input["data"] == null && input["mashupDocument"] == null) {
            return [{
                    message: "At least one of data or mashupDocument must be provided"
                }];
        }
    };
    return DatasetCreateConfigValidator;
}(typeValidator_1.ObjectValidator));
exports.DatasetCreateConfigValidator = DatasetCreateConfigValidator;
var DatasourceConnectionConfigValidator = /** @class */ (function (_super) {
    __extends(DatasourceConnectionConfigValidator, _super);
    function DatasourceConnectionConfigValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    DatasourceConnectionConfigValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "dataCacheMode",
                validators: [validator_1.Validators.dataCacheModeValidator]
            },
            {
                field: "credentials",
                validators: [validator_1.Validators.credentialsValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return DatasourceConnectionConfigValidator;
}(typeValidator_1.ObjectValidator));
exports.DatasourceConnectionConfigValidator = DatasourceConnectionConfigValidator;
var CredentialsValidator = /** @class */ (function (_super) {
    __extends(CredentialsValidator, _super);
    function CredentialsValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    CredentialsValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "credentialType",
                validators: [validator_1.Validators.credentialTypeValidator]
            },
            {
                field: "credentialDetails",
                validators: [validator_1.Validators.credentialDetailsValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return CredentialsValidator;
}(typeValidator_1.ObjectValidator));
exports.CredentialsValidator = CredentialsValidator;
var ColumnSchemaValidator = /** @class */ (function (_super) {
    __extends(ColumnSchemaValidator, _super);
    function ColumnSchemaValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    ColumnSchemaValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "name",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "displayName",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "dataType",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return ColumnSchemaValidator;
}(typeValidator_1.ObjectValidator));
exports.ColumnSchemaValidator = ColumnSchemaValidator;
var TableSchemaValidator = /** @class */ (function (_super) {
    __extends(TableSchemaValidator, _super);
    function TableSchemaValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    TableSchemaValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "name",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "columns",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.columnSchemaArrayValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return TableSchemaValidator;
}(typeValidator_1.ObjectValidator));
exports.TableSchemaValidator = TableSchemaValidator;
var TableDataValidator = /** @class */ (function (_super) {
    __extends(TableDataValidator, _super);
    function TableDataValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    TableDataValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "name",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "rows",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.rawDataValidator]
            }
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return TableDataValidator;
}(typeValidator_1.ObjectValidator));
exports.TableDataValidator = TableDataValidator;


/***/ }),
/* 32 */
/***/ (function(__unused_webpack_module, exports, __nested_webpack_require_232602__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.QuickCreateValidator = void 0;
var multipleFieldsValidator_1 = __nested_webpack_require_232602__(3);
var typeValidator_1 = __nested_webpack_require_232602__(4);
var validator_1 = __nested_webpack_require_232602__(1);
var QuickCreateValidator = /** @class */ (function (_super) {
    __extends(QuickCreateValidator, _super);
    function QuickCreateValidator() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    QuickCreateValidator.prototype.validate = function (input, path, field) {
        if (input == null) {
            return null;
        }
        var errors = _super.prototype.validate.call(this, input, path, field);
        if (errors) {
            return errors;
        }
        var fields = [
            {
                field: "accessToken",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.stringValidator]
            },
            {
                field: "groupId",
                validators: [validator_1.Validators.stringValidator]
            },
            {
                field: "tokenType",
                validators: [validator_1.Validators.tokenTypeValidator]
            },
            {
                field: "theme",
                validators: [validator_1.Validators.customThemeValidator]
            },
            {
                field: "datasetCreateConfig",
                validators: [validator_1.Validators.fieldRequiredValidator, validator_1.Validators.datasetCreateConfigValidator]
            },
        ];
        var multipleFieldsValidator = new multipleFieldsValidator_1.MultipleFieldsValidator(fields);
        return multipleFieldsValidator.validate(input, path, field);
    };
    return QuickCreateValidator;
}(typeValidator_1.ObjectValidator));
exports.QuickCreateValidator = QuickCreateValidator;


/***/ })
/******/ 	]);
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __nested_webpack_require_235634__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId].call(module.exports, module, module.exports, __nested_webpack_require_235634__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	
/******/ 	// startup
/******/ 	// Load entry module and return exports
/******/ 	// This entry module is referenced by other modules so it can't be inlined
/******/ 	var __webpack_exports__ = __nested_webpack_require_235634__(0);
/******/ 	
/******/ 	return __webpack_exports__;
/******/ })()
;
});
//# sourceMappingURL=models.js.map
// SIG // Begin signature block
// SIG // MIIrVgYJKoZIhvcNAQcCoIIrRzCCK0MCAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // /i51IdNsxTS0JqJprFGAbZKQWzw3aaJrQs6hvB+vKCig
// SIG // ghF5MIIIiTCCB3GgAwIBAgITNgAAAanWkDBmQ9sfggAC
// SIG // AAABqTANBgkqhkiG9w0BAQsFADBBMRMwEQYKCZImiZPy
// SIG // LGQBGRYDR0JMMRMwEQYKCZImiZPyLGQBGRYDQU1FMRUw
// SIG // EwYDVQQDEwxBTUUgQ1MgQ0EgMDEwHhcNMjIwNjEwMTgy
// SIG // NzA0WhcNMjMwNjEwMTgyNzA0WjAkMSIwIAYDVQQDExlN
// SIG // aWNyb3NvZnQgQXp1cmUgQ29kZSBTaWduMIIBIjANBgkq
// SIG // hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuLvS3Hq6XM6N
// SIG // 5ZVPdqZQQbTo4WFo9Ar6TqyLpZIqQpNoW9ZG58deayDX
// SIG // VV7wKgn0IAjewM3VfPGtiX8jjOz4VtelbCYnbV9zrqqU
// SIG // rtTlqTbFB1L+UWQO2DLhxB8QybLxi38KaiY1DC6DL5xK
// SIG // uAnIGWnVNS168FihSxIPneGKfG3nJH1CgSA/rJ7w7tnY
// SIG // 8hHlpPpMia6oKVAZSvos9/fDpBmX+cru3sXfEv19s+4O
// SIG // JKLoPlJiNR0PhsqW5hChTn+tjVOBu8Td7tcb+jf9QQs1
// SIG // 2HPBtx3nMNhNlYZQrqXJMUy65RH2zAYAd9N9tdo6VRU/
// SIG // 8vRYzYOrWHSulDVtMn2cjwIDAQABo4IFlTCCBZEwKQYJ
// SIG // KwYBBAGCNxUKBBwwGjAMBgorBgEEAYI3WwEBMAoGCCsG
// SIG // AQUFBwMDMD0GCSsGAQQBgjcVBwQwMC4GJisGAQQBgjcV
// SIG // CIaQ4w2E1bR4hPGLPoWb3RbOnRKBYIPdzWaGlIwyAgFk
// SIG // AgEMMIICdgYIKwYBBQUHAQEEggJoMIICZDBiBggrBgEF
// SIG // BQcwAoZWaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
// SIG // aWluZnJhL0NlcnRzL0JZMlBLSUNTQ0EwMS5BTUUuR0JM
// SIG // X0FNRSUyMENTJTIwQ0ElMjAwMSgyKS5jcnQwUgYIKwYB
// SIG // BQUHMAKGRmh0dHA6Ly9jcmwxLmFtZS5nYmwvYWlhL0JZ
// SIG // MlBLSUNTQ0EwMS5BTUUuR0JMX0FNRSUyMENTJTIwQ0El
// SIG // MjAwMSgyKS5jcnQwUgYIKwYBBQUHMAKGRmh0dHA6Ly9j
// SIG // cmwyLmFtZS5nYmwvYWlhL0JZMlBLSUNTQ0EwMS5BTUUu
// SIG // R0JMX0FNRSUyMENTJTIwQ0ElMjAwMSgyKS5jcnQwUgYI
// SIG // KwYBBQUHMAKGRmh0dHA6Ly9jcmwzLmFtZS5nYmwvYWlh
// SIG // L0JZMlBLSUNTQ0EwMS5BTUUuR0JMX0FNRSUyMENTJTIw
// SIG // Q0ElMjAwMSgyKS5jcnQwUgYIKwYBBQUHMAKGRmh0dHA6
// SIG // Ly9jcmw0LmFtZS5nYmwvYWlhL0JZMlBLSUNTQ0EwMS5B
// SIG // TUUuR0JMX0FNRSUyMENTJTIwQ0ElMjAwMSgyKS5jcnQw
// SIG // ga0GCCsGAQUFBzAChoGgbGRhcDovLy9DTj1BTUUlMjBD
// SIG // UyUyMENBJTIwMDEsQ049QUlBLENOPVB1YmxpYyUyMEtl
// SIG // eSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZp
// SIG // Z3VyYXRpb24sREM9QU1FLERDPUdCTD9jQUNlcnRpZmlj
// SIG // YXRlP2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlmaWNhdGlv
// SIG // bkF1dGhvcml0eTAdBgNVHQ4EFgQUj5gJWFiDzm06yLnX
// SIG // Wf2V9PM6+1cwDgYDVR0PAQH/BAQDAgeAMFAGA1UdEQRJ
// SIG // MEekRTBDMSkwJwYDVQQLEyBNaWNyb3NvZnQgT3BlcmF0
// SIG // aW9ucyBQdWVydG8gUmljbzEWMBQGA1UEBRMNMjM2MTY3
// SIG // KzQ3MDg2MTCCAeYGA1UdHwSCAd0wggHZMIIB1aCCAdGg
// SIG // ggHNhj9odHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtp
// SIG // aW5mcmEvQ1JML0FNRSUyMENTJTIwQ0ElMjAwMSgyKS5j
// SIG // cmyGMWh0dHA6Ly9jcmwxLmFtZS5nYmwvY3JsL0FNRSUy
// SIG // MENTJTIwQ0ElMjAwMSgyKS5jcmyGMWh0dHA6Ly9jcmwy
// SIG // LmFtZS5nYmwvY3JsL0FNRSUyMENTJTIwQ0ElMjAwMSgy
// SIG // KS5jcmyGMWh0dHA6Ly9jcmwzLmFtZS5nYmwvY3JsL0FN
// SIG // RSUyMENTJTIwQ0ElMjAwMSgyKS5jcmyGMWh0dHA6Ly9j
// SIG // cmw0LmFtZS5nYmwvY3JsL0FNRSUyMENTJTIwQ0ElMjAw
// SIG // MSgyKS5jcmyGgb1sZGFwOi8vL0NOPUFNRSUyMENTJTIw
// SIG // Q0ElMjAwMSgyKSxDTj1CWTJQS0lDU0NBMDEsQ049Q0RQ
// SIG // LENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNl
// SIG // cnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9QU1FLERD
// SIG // PUdCTD9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jh
// SIG // c2U/b2JqZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9p
// SIG // bnQwHwYDVR0jBBgwFoAUllGE4Gtve/7YBqvD8oXmKa5q
// SIG // +dQwHwYDVR0lBBgwFgYKKwYBBAGCN1sBAQYIKwYBBQUH
// SIG // AwMwDQYJKoZIhvcNAQELBQADggEBAHD1OJbFZ/tIa5Zp
// SIG // DzeU+mqWHOdF2htAZKicRfNYhaajjyYRvCTUKn/5SZGU
// SIG // KKdVmsxiFtCOp2lJ2+C3b7IJukkqC9SmpIkQLhBuz7uK
// SIG // 4NsXB6Xn3Iv32YuKeH4sqdRqJMCezhsale/Sh6fecsVW
// SIG // pJnsvfXxdXBCyoVbAZCZCQN3dOXUz4DtEfV2fxhRzTfS
// SIG // UhKsr1VSY9HC/myediSqvqd3zfgK9j6IR0DcL3WkKiV0
// SIG // B/dnYwntnntrhFxGYQuPPXBA7xX10SB/8CVA8V1NovOk
// SIG // tGO5cgvmVMe5pA2m9M7sOBgFkjXgPD7i4PoL5X0mK+6b
// SIG // nchiEZj1C5l1X6LzJH4wggjoMIIG0KADAgECAhMfAAAA
// SIG // UeqP9pxzDKg7AAAAAABRMA0GCSqGSIb3DQEBCwUAMDwx
// SIG // EzARBgoJkiaJk/IsZAEZFgNHQkwxEzARBgoJkiaJk/Is
// SIG // ZAEZFgNBTUUxEDAOBgNVBAMTB2FtZXJvb3QwHhcNMjEw
// SIG // NTIxMTg0NDE0WhcNMjYwNTIxMTg1NDE0WjBBMRMwEQYK
// SIG // CZImiZPyLGQBGRYDR0JMMRMwEQYKCZImiZPyLGQBGRYD
// SIG // QU1FMRUwEwYDVQQDEwxBTUUgQ1MgQ0EgMDEwggEiMA0G
// SIG // CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDJmlIJfQGe
// SIG // jVbXKpcyFPoFSUllalrinfEV6JMc7i+bZDoL9rNHnHDG
// SIG // fJgeuRIYO1LY/1f4oMTrhXbSaYRCS5vGc8145WcTZG90
// SIG // 8bGDCWr4GFLc411WxA+Pv2rteAcz0eHMH36qTQ8L0o3X
// SIG // Ob2n+x7KJFLokXV1s6pF/WlSXsUBXGaCIIWBXyEchv+s
// SIG // M9eKDsUOLdLTITHYJQNWkiryMSEbxqdQUTVZjEz6eLRL
// SIG // kofDAo8pXirIYOgM770CYOiZrcKHK7lYOVblx22pdNaw
// SIG // Y8Te6a2dfoCaWV1QUuazg5VHiC4p/6fksgEILptOKhx9
// SIG // c+iapiNhMrHsAYx9pUtppeaFAgMBAAGjggTcMIIE2DAS
// SIG // BgkrBgEEAYI3FQEEBQIDAgACMCMGCSsGAQQBgjcVAgQW
// SIG // BBQSaCRCIUfL1Gu+Mc8gpMALI38/RzAdBgNVHQ4EFgQU
// SIG // llGE4Gtve/7YBqvD8oXmKa5q+dQwggEEBgNVHSUEgfww
// SIG // gfkGBysGAQUCAwUGCCsGAQUFBwMBBggrBgEFBQcDAgYK
// SIG // KwYBBAGCNxQCAQYJKwYBBAGCNxUGBgorBgEEAYI3CgMM
// SIG // BgkrBgEEAYI3FQYGCCsGAQUFBwMJBggrBgEFBQgCAgYK
// SIG // KwYBBAGCN0ABAQYLKwYBBAGCNwoDBAEGCisGAQQBgjcK
// SIG // AwQGCSsGAQQBgjcVBQYKKwYBBAGCNxQCAgYKKwYBBAGC
// SIG // NxQCAwYIKwYBBQUHAwMGCisGAQQBgjdbAQEGCisGAQQB
// SIG // gjdbAgEGCisGAQQBgjdbAwEGCisGAQQBgjdbBQEGCisG
// SIG // AQQBgjdbBAEGCisGAQQBgjdbBAIwGQYJKwYBBAGCNxQC
// SIG // BAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMBIGA1Ud
// SIG // EwEB/wQIMAYBAf8CAQAwHwYDVR0jBBgwFoAUKV5RXmSu
// SIG // NLnrrJwNp4x1AdEJCygwggFoBgNVHR8EggFfMIIBWzCC
// SIG // AVegggFToIIBT4YxaHR0cDovL2NybC5taWNyb3NvZnQu
// SIG // Y29tL3BraWluZnJhL2NybC9hbWVyb290LmNybIYjaHR0
// SIG // cDovL2NybDIuYW1lLmdibC9jcmwvYW1lcm9vdC5jcmyG
// SIG // I2h0dHA6Ly9jcmwzLmFtZS5nYmwvY3JsL2FtZXJvb3Qu
// SIG // Y3JshiNodHRwOi8vY3JsMS5hbWUuZ2JsL2NybC9hbWVy
// SIG // b290LmNybIaBqmxkYXA6Ly8vQ049YW1lcm9vdCxDTj1B
// SIG // TUVSb290LENOPUNEUCxDTj1QdWJsaWMlMjBLZXklMjBT
// SIG // ZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0
// SIG // aW9uLERDPUFNRSxEQz1HQkw/Y2VydGlmaWNhdGVSZXZv
// SIG // Y2F0aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERp
// SIG // c3RyaWJ1dGlvblBvaW50MIIBqwYIKwYBBQUHAQEEggGd
// SIG // MIIBmTBHBggrBgEFBQcwAoY7aHR0cDovL2NybC5taWNy
// SIG // b3NvZnQuY29tL3BraWluZnJhL2NlcnRzL0FNRVJvb3Rf
// SIG // YW1lcm9vdC5jcnQwNwYIKwYBBQUHMAKGK2h0dHA6Ly9j
// SIG // cmwyLmFtZS5nYmwvYWlhL0FNRVJvb3RfYW1lcm9vdC5j
// SIG // cnQwNwYIKwYBBQUHMAKGK2h0dHA6Ly9jcmwzLmFtZS5n
// SIG // YmwvYWlhL0FNRVJvb3RfYW1lcm9vdC5jcnQwNwYIKwYB
// SIG // BQUHMAKGK2h0dHA6Ly9jcmwxLmFtZS5nYmwvYWlhL0FN
// SIG // RVJvb3RfYW1lcm9vdC5jcnQwgaIGCCsGAQUFBzAChoGV
// SIG // bGRhcDovLy9DTj1hbWVyb290LENOPUFJQSxDTj1QdWJs
// SIG // aWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxD
// SIG // Tj1Db25maWd1cmF0aW9uLERDPUFNRSxEQz1HQkw/Y0FD
// SIG // ZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNlcnRp
// SIG // ZmljYXRpb25BdXRob3JpdHkwDQYJKoZIhvcNAQELBQAD
// SIG // ggIBAFAQI7dPD+jfXtGt3vJp2pyzA/HUu8hjKaRpM3op
// SIG // ya5G3ocprRd7vdTHb8BDfRN+AD0YEmeDB5HKQoG6xHPI
// SIG // 5TXuIi5sm/LeADbV3C2q0HQOygS/VT+m1W7a/752hMIn
// SIG // +L4ZuyxVeSBpfwf7oQ4YSZPh6+ngZvBHgfBaVz4O9/wc
// SIG // fw91QDZnTgK9zAh9yRKKls2bziPEnxeOZMVNaxyV0v15
// SIG // 2PY2xjqIafIkUjK6vY9LtVFjJXenVUAmn3WCPWNFC1YT
// SIG // IIHw/mD2cTfPy7QA1pT+GPARAKt0bKtq9aCd/Ym0b5tP
// SIG // bpgCiRtzyb7fbNS1dE740re0COE67YV2wbeo2sXixzvL
// SIG // ftH8L7s9xv9wV+G22qyKt6lmKLjFK1yMw4Ni5fMabcgm
// SIG // zRvSjAcbqgp3tk4a8emaaH0rz8MuuIP+yrxtREPXSqL/
// SIG // C5bzMzsikuDW9xH10graZzSmPjilzpRfRdu20/9UQmC7
// SIG // eVPZ4j1WNa1oqPHfzET3ChIzJ6Q9G3NPCB+7KwX0OQmK
// SIG // yv7IDimj8U/GlsHD1z+EF/fYMf8YXG15LamaOAohsw/y
// SIG // wO6SYSreVW+5Y0mzJutnBC9Cm9ozj1+/4kqksrlhZgR/
// SIG // CSxhFH3BTweH8gP2FEISRtShDZbuYymynY1un+RyfiK9
// SIG // +iVTLdD1h/SxyxDpZMtimb4CgJQlMYIZNTCCGTECAQEw
// SIG // WDBBMRMwEQYKCZImiZPyLGQBGRYDR0JMMRMwEQYKCZIm
// SIG // iZPyLGQBGRYDQU1FMRUwEwYDVQQDEwxBTUUgQ1MgQ0Eg
// SIG // MDECEzYAAAGp1pAwZkPbH4IAAgAAAakwDQYJYIZIAWUD
// SIG // BAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
// SIG // AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUw
// SIG // LwYJKoZIhvcNAQkEMSIEIEgzLPlSRdtRALewHjk0YF65
// SIG // k1BN+zhlWpF7dpatkUNNMEIGCisGAQQBgjcCAQwxNDAy
// SIG // oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8v
// SIG // d3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAE
// SIG // ggEAo7s9H4+5ZCFpGU+mzKmSZNKGszg3RSKhV5NPmrAP
// SIG // MIUNLJvqKkNJ/782HHPkUqa5fxJpeKTY4oRyv2Jr8Edf
// SIG // eB/84/cwhtKbj+TLdHX4mro+OKoQmOC6MvxT3Jg/lWsT
// SIG // qiYJoRQ1hajAdRsZ8ukon3JoSdQRTcQOjchiX5p+VarN
// SIG // LQlesuKl8srWej8Col6ASZNierCPh7Zep+8YnDQGxwXt
// SIG // 9PvGetnUTF/4kw42UQNn8kABdhJYfpuveqXIfAarCLgG
// SIG // Ev3PTG0dA/c2oqHlqwZw/BBOL4LbVEbGFGfY4L3j8Pgc
// SIG // axN+CvwzXA6YQWIRcrp+KnTSQoenP051gteIhaGCFv0w
// SIG // ghb5BgorBgEEAYI3AwMBMYIW6TCCFuUGCSqGSIb3DQEH
// SIG // AqCCFtYwghbSAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFR
// SIG // BgsqhkiG9w0BCRABBKCCAUAEggE8MIIBOAIBAQYKKwYB
// SIG // BAGEWQoDATAxMA0GCWCGSAFlAwQCAQUABCC3cDSDpi62
// SIG // ZHR/9yf8bEyPbB6XeS1AF23Ph/1CEGjCVAIGY2z2CHbT
// SIG // GBMyMDIyMTEyMDA3NDQ0NC4xMzVaMASAAgH0oIHQpIHN
// SIG // MIHKMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
// SIG // Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
// SIG // TWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxN
// SIG // aWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYD
// SIG // VQQLEx1UaGFsZXMgVFNTIEVTTjpENkJELUUzRTctMTY4
// SIG // NTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
// SIG // U2VydmljZaCCEVQwggcMMIIE9KADAgECAhMzAAABx/sA
// SIG // oEpb8ifcAAEAAAHHMA0GCSqGSIb3DQEBCwUAMHwxCzAJ
// SIG // BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
// SIG // DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
// SIG // ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
// SIG // dCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIyMTEwNDE5
// SIG // MDEzNVoXDTI0MDIwMjE5MDEzNVowgcoxCzAJBgNVBAYT
// SIG // AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
// SIG // EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
// SIG // cG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
// SIG // aWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBU
// SIG // U1MgRVNOOkQ2QkQtRTNFNy0xNjg1MSUwIwYDVQQDExxN
// SIG // aWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjAN
// SIG // BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAr0LcVtna
// SIG // tNFMBrQTtG9P8ISAPyyGmxNfhEzaOVlt088pBUFAIasm
// SIG // N/eOijE6Ucaf3c2bVnN/02ih0smSqYkm5P3ZwU7ZW202
// SIG // b6cPDJjXcrjJj0qfnuccBtE3WU0vZ8CiQD7qrKxeF8YB
// SIG // NcS+PVtvsqhd5YW6AwhWqhjw1mYuLetF5b6aPif/3Rzl
// SIG // yqG3SV7QPiSJends7gG435Rsy1HJ4XnqztOJR41I0j3E
// SIG // Q05JMF5QNRi7kT6vXTT+MHVj27FVQ7bef/U+2EAbFj2X
// SIG // 2AOWbvglYaYnM3m/I/OWDHUgGw8KIdsDh3W1eusnF2D7
// SIG // oenGgtahs+S1G5Uolf5ESg/9Z+38rhQwLgokY5k6p8k5
// SIG // arYWtszdJK6JiIRl843H74k7+QqlT2LbAQPq8ivQv0gd
// SIG // clW2aJun1KrW+v52R3vAHCOtbUmxvD1eNGHqGqLagtlq
// SIG // 9UFXKXuXnqXJqruCYmfwdFMD0UP6ii1lFdeKL87PdjdA
// SIG // wyCiVcCEoLnvDzyvjNjxtkTdz6R4yF1N/X4PSQH4Flgs
// SIG // lyBIXggaSlPtvPuxAtuac/ITj4k0IRShGiYLBM2Dw6oe
// SIG // sLOoxe07OUPO+qXXOcJMVHhE0MlhhnxfN2B1JWFPWwQ6
// SIG // ooWiqAOQDqzcDx+79shxA1Cx0K70eOBplMog27gYoLpB
// SIG // v7nRz4tHqoTyvA0CAwEAAaOCATYwggEyMB0GA1UdDgQW
// SIG // BBQFUNLdHD7BAF/VU/X/eEHLiUSSIDAfBgNVHSMEGDAW
// SIG // gBSfpxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBW
// SIG // MFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
// SIG // cGtpb3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1w
// SIG // JTIwUENBJTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEE
// SIG // YDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jv
// SIG // c29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUy
// SIG // MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAM
// SIG // BgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMI
// SIG // MA0GCSqGSIb3DQEBCwUAA4ICAQDQy5c8ogP0y8xAsLVc
// SIG // a07wWy1mT+nqYgAFnz2972kNO+KJ7AE4f+SVbvOnkeeu
// SIG // OPq3xc+6TS8g3FuKKYEwYqvnRHxX58tjlscZsZeKnu7f
// SIG // GNUlpNT9bOQFHWALURuoXp8TLHhxj3PEq9jzFYBP2YNM
// SIG // Lol70ojY1qpze3nMMJfpdurdBBpaOLlJmRNTLhxd+RJG
// SIG // JQbY1XAcx6p/FigwqBasSDUxp+0yFPEBB9uBE3KILAtq
// SIG // 6fczGp4EMeon6YmkyCGAtXMKDFQQgdP/ITe7VghAVbPT
// SIG // VlP3hY1dFgc+t8YK2obFSFVKslkASATDHulCMht+WrIs
// SIG // ukclEUP9DaMmpq7S0RLODMicI6PtqqGOhdnaRltA0d+W
// SIG // f+0tPt9SUVtrPJyO7WMPKbykCRXzmHK06zr0kn1YiUYN
// SIG // XCsOgaHF5ImO2ZwQ54UE1I55jjUdldyjy/UPJgxRm9Ny
// SIG // XeO7adYr8K8f6Q2nPF0vWqFG7ewwaAl5ClKerzshfhB8
// SIG // zujVR0d1Ra7Z01lnXYhWuPqVZayFl7JHr6i6huhpU6BQ
// SIG // 6/VgY0cBiksX4mNM+ISY81T1RYt7fWATNu/zkjINczip
// SIG // zbfg5S+3fCAo8gVB6+6A5L0vBg39dsFITv6MWJuQ8ZZy
// SIG // 7fwlFBZE4d5IFbRudakNwKGdyLGM2otaNq7wm3ku7x41
// SIG // UGAmkDCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkA
// SIG // AAAAABUwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYT
// SIG // AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
// SIG // EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
// SIG // cG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290
// SIG // IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDEwMB4XDTIx
// SIG // MDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIyNVowfDELMAkG
// SIG // A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
// SIG // BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
// SIG // dCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
// SIG // IFRpbWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3
// SIG // DQEBAQUAA4ICDwAwggIKAoICAQDk4aZM57RyIQt5osvX
// SIG // JHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/bErg4r25Phdg
// SIG // M/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjo
// SIG // YH1qUoNEt6aORmsHFPPFdvWGUNzBRMhxXFExN6AKOG6N
// SIG // 7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41JmTamDu6Gnsz
// SIG // rYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v3byN
// SIG // pOORj7I5LFGc6XBpDco2LXCOMcg1KL3jtIckw+DJj361
// SIG // VI/c+gVVmG1oO5pGve2krnopN6zL64NF50ZuyjLVwIYw
// SIG // XE8s4mKyzbnijYjklqwBSru+cakXW2dg3viSkR4dPf0g
// SIG // z3N9QZpGdc3EXzTdEonW/aUgfX782Z5F37ZyL9t9X4C6
// SIG // 26p+Nuw2TPYrbqgSUei/BQOj0XOmTTd0lBw0gg/wEPK3
// SIG // Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlMjgK8QmguEOqE
// SIG // UUbi0b1qGFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdj
// SIG // bwzJNmSLW6CmgyFdXzB0kZSU2LlQ+QuJYfM2BjUYhEfb
// SIG // 3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzFER1y7435UsSF
// SIG // F5PAPBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+
// SIG // auIurQIDAQABo4IB3TCCAdkwEgYJKwYBBAGCNxUBBAUC
// SIG // AwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS/mTEmr6CkTxG
// SIG // NSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWn
// SIG // G1M1GelyMFwGA1UdIARVMFMwUQYMKwYBBAGCN0yDfQEB
// SIG // MEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9z
// SIG // b2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0
// SIG // bTATBgNVHSUEDDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3
// SIG // FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
// SIG // VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+ii
// SIG // XGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVo
// SIG // dHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9w
// SIG // cm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5j
// SIG // cmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5o
// SIG // dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRz
// SIG // L01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDANBgkq
// SIG // hkiG9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL
// SIG // /Klv6lwUtj5OR2R4sQaTlz0xM7U518JxNj/aZGx80HU5
// SIG // bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6th542DYunKmC
// SIG // VgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1
// SIG // bSNU5HhTdSRXud2f8449xvNo32X2pFaq95W2KFUn0CS9
// SIG // QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBewVIVCs/wMnosZ
// SIG // iefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU6ZGy
// SIG // qVvfSaN0DLzskYDSPeZKPmY7T7uG+jIa2Zb0j/aRAfbO
// SIG // xnT99kxybxCrdTDFNLB62FD+CljdQDzHVG2dY3RILLFO
// SIG // Ry3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/HltEAY5a
// SIG // GZFrDZ+kKNxnGSgkujhLmm77IVRrakURR6nxt67I6Ile
// SIG // T53S0Ex2tVdUCbFpAUR+fKFhbHP+CrvsQWY9af3LwUFJ
// SIG // fn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKiexcdFYmNcP7n
// SIG // tdAoGokLjzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurw
// SIG // J0I9JZTmdHRbatGePu1+oDEzfbzL6Xu/OHBE0ZDxyKs6
// SIG // ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKh
// SIG // ggLLMIICNAIBATCB+KGB0KSBzTCByjELMAkGA1UEBhMC
// SIG // VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
// SIG // B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
// SIG // b3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJp
// SIG // Y2EgT3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRT
// SIG // UyBFU046RDZCRC1FM0U3LTE2ODUxJTAjBgNVBAMTHE1p
// SIG // Y3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAH
// SIG // BgUrDgMCGgMVAOIASP0JSbv5R23wxciQivHyckYooIGD
// SIG // MIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
// SIG // c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
// SIG // BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
// SIG // AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAw
// SIG // DQYJKoZIhvcNAQEFBQACBQDnI/oLMCIYDzIwMjIxMTIw
// SIG // MDg1NzQ3WhgPMjAyMjExMjEwODU3NDdaMHQwOgYKKwYB
// SIG // BAGEWQoEATEsMCowCgIFAOcj+gsCAQAwBwIBAAICHBww
// SIG // BwIBAAICEiowCgIFAOclS4sCAQAwNgYKKwYBBAGEWQoE
// SIG // AjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEK
// SIG // MAgCAQACAwGGoDANBgkqhkiG9w0BAQUFAAOBgQBT0J06
// SIG // x6PZG4//134XJhg5O4xmWeRezqg2dN507dbDtSo+CLxX
// SIG // H9ES2gCO7yF0PiYpmHD3wCISVhYOqZUQS8fyttZ0c0y3
// SIG // SxBg3p+areajBqCwlAsA1Jj0P9xFZcIjdKHDmQdLmFV+
// SIG // PSh+rV/X12A3iS9ApYPkJS3yIjXP4HfR+zGCBA0wggQJ
// SIG // AgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
// SIG // YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
// SIG // VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
// SIG // BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
// SIG // AhMzAAABx/sAoEpb8ifcAAEAAAHHMA0GCWCGSAFlAwQC
// SIG // AQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQ
// SIG // AQQwLwYJKoZIhvcNAQkEMSIEIDPjs8coVkVPbRmBuFRv
// SIG // rxI3sUvngRnt3OBZCvmJPX/xMIH6BgsqhkiG9w0BCRAC
// SIG // LzGB6jCB5zCB5DCBvQQgR+fl2+JSskULOeVYLbeMgk7H
// SIG // dIbREmAsjwtcy6MJkskwgZgwgYCkfjB8MQswCQYDVQQG
// SIG // EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
// SIG // BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
// SIG // cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
// SIG // ZS1TdGFtcCBQQ0EgMjAxMAITMwAAAcf7AKBKW/In3AAB
// SIG // AAABxzAiBCAc2zxBUP4w0UoaCVlGQTdUxjMV2MuJl3TI
// SIG // Mgs34gPuaDANBgkqhkiG9w0BAQsFAASCAgBlUsc9c0V+
// SIG // HDcIQQj9Y4Ub2P93+r/Fy4A32eL7fUnyD19zSC5bvD/r
// SIG // 3HIwoFg+19MJhmHovw3hFs5k5pyehwoSjA3yUX71kjbq
// SIG // QiqUTL1A6XomxjRp74fT+Q0b/CztpyB5OLRH3b3dd/Bi
// SIG // CofsDPzhsJdNxhWrLZQjD4/cbetxXMvN6kbXepug/nqD
// SIG // iloPxzy9hAjHLRo9ontyG5qkM365aNOc3gULdNuvCEiw
// SIG // /qJ3XF/3OcLVaPtL4FLsLBZKWZK0DE92rj66HhjSTiP7
// SIG // JeC5dJKvU3PwafqiaAuK+UTxWKFo/Pc38d5LONVO3F/S
// SIG // XNlywNSaqTc46cd3a6V/QISNhQvM9G1gPGoK1pW1czlK
// SIG // +upSR4bdf18EQZNr81B9zkN1RK8Qo3kyAxT42Pq+GktX
// SIG // pz2jRRCOnWBcL+JFE2Jwf3vsg9zLPGDrfSsPGdcz3WiE
// SIG // ZchATs23Qv+789h1PFBWXCS6HA2sOgFMyW92i/xj0xPW
// SIG // OpGuXoV3Sz2CpdhB5rVLNvdFiKluwcI3svDTvS5G8vrs
// SIG // te0ZnWIz8BtYigYGWaDIlSo8Dm+kbxM5Y7rYLho3ZHB0
// SIG // DMnWzJoJko1oX+6n7/L5oyCmE9WVialEn2JNL6Dn852n
// SIG // o497Zeqt9f8oj2UtHJvzxAhHvq1/fNNqdlY1Ws7WlDr2
// SIG // 9tddA7XPj/kzLA==
// SIG // End signature block


/***/ }),

/***/ "./node_modules/powerbi-router/dist/router.js":
/*!****************************************************!*\
  !*** ./node_modules/powerbi-router/dist/router.js ***!
  \****************************************************/
/***/ (function(module) {

/*! powerbi-router v0.1.5 | (c) 2016 Microsoft Corporation MIT */
(function webpackUniversalModuleDefinition(root, factory) {
	if(true)
		module.exports = factory();
	else {}
})(this, function() {
return /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __nested_webpack_require_617__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;
/******/
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __nested_webpack_require_617__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__nested_webpack_require_617__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__nested_webpack_require_617__.c = installedModules;
/******/
/******/ 	// __webpack_public_path__
/******/ 	__nested_webpack_require_617__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __nested_webpack_require_617__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports, __nested_webpack_require_1897__) {

	"use strict";
	var RouteRecognizer = __nested_webpack_require_1897__(1);
	var Router = (function () {
	    function Router(handlers) {
	        this.handlers = handlers;
	        /**
	         * TODO: look at generating the router dynamically based on list of supported http methods
	         * instead of hardcoding the creation of these and the methods.
	         */
	        this.getRouteRecognizer = new RouteRecognizer();
	        this.patchRouteRecognizer = new RouteRecognizer();
	        this.postRouteRecognizer = new RouteRecognizer();
	        this.putRouteRecognizer = new RouteRecognizer();
	        this.deleteRouteRecognizer = new RouteRecognizer();
	    }
	    Router.prototype.get = function (url, handler) {
	        this.registerHandler(this.getRouteRecognizer, "GET", url, handler);
	        return this;
	    };
	    Router.prototype.patch = function (url, handler) {
	        this.registerHandler(this.patchRouteRecognizer, "PATCH", url, handler);
	        return this;
	    };
	    Router.prototype.post = function (url, handler) {
	        this.registerHandler(this.postRouteRecognizer, "POST", url, handler);
	        return this;
	    };
	    Router.prototype.put = function (url, handler) {
	        this.registerHandler(this.putRouteRecognizer, "PUT", url, handler);
	        return this;
	    };
	    Router.prototype.delete = function (url, handler) {
	        this.registerHandler(this.deleteRouteRecognizer, "DELETE", url, handler);
	        return this;
	    };
	    /**
	     * TODO: This method could use some refactoring.  There is conflict of interest between keeping clean separation of test and handle method
	     * Test method only returns boolean indicating if request can be handled, and handle method has opportunity to modify response and return promise of it.
	     * In the case of the router with route-recognizer where handlers are associated with routes, this already guarantees that only one handler is selected and makes the test method feel complicated
	     * Will leave as is an investigate cleaner ways at later time.
	     */
	    Router.prototype.registerHandler = function (routeRecognizer, method, url, handler) {
	        var routeRecognizerHandler = function (request) {
	            var response = new Response();
	            return Promise.resolve(handler(request, response))
	                .then(function (x) { return response; });
	        };
	        routeRecognizer.add([
	            { path: url, handler: routeRecognizerHandler }
	        ]);
	        var internalHandler = {
	            test: function (request) {
	                if (request.method !== method) {
	                    return false;
	                }
	                var matchingRoutes = routeRecognizer.recognize(request.url);
	                if (matchingRoutes === undefined) {
	                    return false;
	                }
	                /**
	                 * Copy parameters from recognized route to the request so they can be used within the handler function
	                 * This isn't ideal because it is side affect which modifies the request instead of strictly testing for true or false
	                 * but I don't see a better place to put this.  If we move it between the call to test and the handle it becomes part of the window post message proxy
	                 * even though it's responsibility is related to routing.
	                 */
	                var route = matchingRoutes[0];
	                request.params = route.params;
	                request.queryParams = matchingRoutes.queryParams;
	                request.handler = route.handler;
	                return true;
	            },
	            handle: function (request) {
	                return request.handler(request);
	            }
	        };
	        this.handlers.addHandler(internalHandler);
	    };
	    return Router;
	}());
	exports.Router = Router;
	var Response = (function () {
	    function Response() {
	        this.statusCode = 200;
	        this.headers = {};
	        this.body = null;
	    }
	    Response.prototype.send = function (statusCode, body) {
	        this.statusCode = statusCode;
	        this.body = body;
	    };
	    return Response;
	}());
	exports.Response = Response;


/***/ },
/* 1 */
/***/ function(module, exports, __nested_webpack_require_6218__) {

	var __WEBPACK_AMD_DEFINE_RESULT__;/* WEBPACK VAR INJECTION */(function(module) {(function() {
	    "use strict";
	    function $$route$recognizer$dsl$$Target(path, matcher, delegate) {
	      this.path = path;
	      this.matcher = matcher;
	      this.delegate = delegate;
	    }
	
	    $$route$recognizer$dsl$$Target.prototype = {
	      to: function(target, callback) {
	        var delegate = this.delegate;
	
	        if (delegate && delegate.willAddRoute) {
	          target = delegate.willAddRoute(this.matcher.target, target);
	        }
	
	        this.matcher.add(this.path, target);
	
	        if (callback) {
	          if (callback.length === 0) { throw new Error("You must have an argument in the function passed to `to`"); }
	          this.matcher.addChild(this.path, target, callback, this.delegate);
	        }
	        return this;
	      }
	    };
	
	    function $$route$recognizer$dsl$$Matcher(target) {
	      this.routes = {};
	      this.children = {};
	      this.target = target;
	    }
	
	    $$route$recognizer$dsl$$Matcher.prototype = {
	      add: function(path, handler) {
	        this.routes[path] = handler;
	      },
	
	      addChild: function(path, target, callback, delegate) {
	        var matcher = new $$route$recognizer$dsl$$Matcher(target);
	        this.children[path] = matcher;
	
	        var match = $$route$recognizer$dsl$$generateMatch(path, matcher, delegate);
	
	        if (delegate && delegate.contextEntered) {
	          delegate.contextEntered(target, match);
	        }
	
	        callback(match);
	      }
	    };
	
	    function $$route$recognizer$dsl$$generateMatch(startingPath, matcher, delegate) {
	      return function(path, nestedCallback) {
	        var fullPath = startingPath + path;
	
	        if (nestedCallback) {
	          nestedCallback($$route$recognizer$dsl$$generateMatch(fullPath, matcher, delegate));
	        } else {
	          return new $$route$recognizer$dsl$$Target(startingPath + path, matcher, delegate);
	        }
	      };
	    }
	
	    function $$route$recognizer$dsl$$addRoute(routeArray, path, handler) {
	      var len = 0;
	      for (var i=0; i<routeArray.length; i++) {
	        len += routeArray[i].path.length;
	      }
	
	      path = path.substr(len);
	      var route = { path: path, handler: handler };
	      routeArray.push(route);
	    }
	
	    function $$route$recognizer$dsl$$eachRoute(baseRoute, matcher, callback, binding) {
	      var routes = matcher.routes;
	
	      for (var path in routes) {
	        if (routes.hasOwnProperty(path)) {
	          var routeArray = baseRoute.slice();
	          $$route$recognizer$dsl$$addRoute(routeArray, path, routes[path]);
	
	          if (matcher.children[path]) {
	            $$route$recognizer$dsl$$eachRoute(routeArray, matcher.children[path], callback, binding);
	          } else {
	            callback.call(binding, routeArray);
	          }
	        }
	      }
	    }
	
	    var $$route$recognizer$dsl$$default = function(callback, addRouteCallback) {
	      var matcher = new $$route$recognizer$dsl$$Matcher();
	
	      callback($$route$recognizer$dsl$$generateMatch("", matcher, this.delegate));
	
	      $$route$recognizer$dsl$$eachRoute([], matcher, function(route) {
	        if (addRouteCallback) { addRouteCallback(this, route); }
	        else { this.add(route); }
	      }, this);
	    };
	
	    var $$route$recognizer$$specials = [
	      '/', '.', '*', '+', '?', '|',
	      '(', ')', '[', ']', '{', '}', '\\'
	    ];
	
	    var $$route$recognizer$$escapeRegex = new RegExp('(\\' + $$route$recognizer$$specials.join('|\\') + ')', 'g');
	
	    function $$route$recognizer$$isArray(test) {
	      return Object.prototype.toString.call(test) === "[object Array]";
	    }
	
	    // A Segment represents a segment in the original route description.
	    // Each Segment type provides an `eachChar` and `regex` method.
	    //
	    // The `eachChar` method invokes the callback with one or more character
	    // specifications. A character specification consumes one or more input
	    // characters.
	    //
	    // The `regex` method returns a regex fragment for the segment. If the
	    // segment is a dynamic of star segment, the regex fragment also includes
	    // a capture.
	    //
	    // A character specification contains:
	    //
	    // * `validChars`: a String with a list of all valid characters, or
	    // * `invalidChars`: a String with a list of all invalid characters
	    // * `repeat`: true if the character specification can repeat
	
	    function $$route$recognizer$$StaticSegment(string) { this.string = string; }
	    $$route$recognizer$$StaticSegment.prototype = {
	      eachChar: function(currentState) {
	        var string = this.string, ch;
	
	        for (var i=0; i<string.length; i++) {
	          ch = string.charAt(i);
	          currentState = currentState.put({ invalidChars: undefined, repeat: false, validChars: ch });
	        }
	
	        return currentState;
	      },
	
	      regex: function() {
	        return this.string.replace($$route$recognizer$$escapeRegex, '\\$1');
	      },
	
	      generate: function() {
	        return this.string;
	      }
	    };
	
	    function $$route$recognizer$$DynamicSegment(name) { this.name = name; }
	    $$route$recognizer$$DynamicSegment.prototype = {
	      eachChar: function(currentState) {
	        return currentState.put({ invalidChars: "/", repeat: true, validChars: undefined });
	      },
	
	      regex: function() {
	        return "([^/]+)";
	      },
	
	      generate: function(params) {
	        return params[this.name];
	      }
	    };
	
	    function $$route$recognizer$$StarSegment(name) { this.name = name; }
	    $$route$recognizer$$StarSegment.prototype = {
	      eachChar: function(currentState) {
	        return currentState.put({ invalidChars: "", repeat: true, validChars: undefined });
	      },
	
	      regex: function() {
	        return "(.+)";
	      },
	
	      generate: function(params) {
	        return params[this.name];
	      }
	    };
	
	    function $$route$recognizer$$EpsilonSegment() {}
	    $$route$recognizer$$EpsilonSegment.prototype = {
	      eachChar: function(currentState) {
	        return currentState;
	      },
	      regex: function() { return ""; },
	      generate: function() { return ""; }
	    };
	
	    function $$route$recognizer$$parse(route, names, specificity) {
	      // normalize route as not starting with a "/". Recognition will
	      // also normalize.
	      if (route.charAt(0) === "/") { route = route.substr(1); }
	
	      var segments = route.split("/");
	      var results = new Array(segments.length);
	
	      // A routes has specificity determined by the order that its different segments
	      // appear in. This system mirrors how the magnitude of numbers written as strings
	      // works.
	      // Consider a number written as: "abc". An example would be "200". Any other number written
	      // "xyz" will be smaller than "abc" so long as `a > z`. For instance, "199" is smaller
	      // then "200", even though "y" and "z" (which are both 9) are larger than "0" (the value
	      // of (`b` and `c`). This is because the leading symbol, "2", is larger than the other
	      // leading symbol, "1".
	      // The rule is that symbols to the left carry more weight than symbols to the right
	      // when a number is written out as a string. In the above strings, the leading digit
	      // represents how many 100's are in the number, and it carries more weight than the middle
	      // number which represents how many 10's are in the number.
	      // This system of number magnitude works well for route specificity, too. A route written as
	      // `a/b/c` will be more specific than `x/y/z` as long as `a` is more specific than
	      // `x`, irrespective of the other parts.
	      // Because of this similarity, we assign each type of segment a number value written as a
	      // string. We can find the specificity of compound routes by concatenating these strings
	      // together, from left to right. After we have looped through all of the segments,
	      // we convert the string to a number.
	      specificity.val = '';
	
	      for (var i=0; i<segments.length; i++) {
	        var segment = segments[i], match;
	
	        if (match = segment.match(/^:([^\/]+)$/)) {
	          results[i] = new $$route$recognizer$$DynamicSegment(match[1]);
	          names.push(match[1]);
	          specificity.val += '3';
	        } else if (match = segment.match(/^\*([^\/]+)$/)) {
	          results[i] = new $$route$recognizer$$StarSegment(match[1]);
	          specificity.val += '1';
	          names.push(match[1]);
	        } else if(segment === "") {
	          results[i] = new $$route$recognizer$$EpsilonSegment();
	          specificity.val += '2';
	        } else {
	          results[i] = new $$route$recognizer$$StaticSegment(segment);
	          specificity.val += '4';
	        }
	      }
	
	      specificity.val = +specificity.val;
	
	      return results;
	    }
	
	    // A State has a character specification and (`charSpec`) and a list of possible
	    // subsequent states (`nextStates`).
	    //
	    // If a State is an accepting state, it will also have several additional
	    // properties:
	    //
	    // * `regex`: A regular expression that is used to extract parameters from paths
	    //   that reached this accepting state.
	    // * `handlers`: Information on how to convert the list of captures into calls
	    //   to registered handlers with the specified parameters
	    // * `types`: How many static, dynamic or star segments in this route. Used to
	    //   decide which route to use if multiple registered routes match a path.
	    //
	    // Currently, State is implemented naively by looping over `nextStates` and
	    // comparing a character specification against a character. A more efficient
	    // implementation would use a hash of keys pointing at one or more next states.
	
	    function $$route$recognizer$$State(charSpec) {
	      this.charSpec = charSpec;
	      this.nextStates = [];
	      this.charSpecs = {};
	      this.regex = undefined;
	      this.handlers = undefined;
	      this.specificity = undefined;
	    }
	
	    $$route$recognizer$$State.prototype = {
	      get: function(charSpec) {
	        if (this.charSpecs[charSpec.validChars]) {
	          return this.charSpecs[charSpec.validChars];
	        }
	
	        var nextStates = this.nextStates;
	
	        for (var i=0; i<nextStates.length; i++) {
	          var child = nextStates[i];
	
	          var isEqual = child.charSpec.validChars === charSpec.validChars;
	          isEqual = isEqual && child.charSpec.invalidChars === charSpec.invalidChars;
	
	          if (isEqual) {
	            this.charSpecs[charSpec.validChars] = child;
	            return child;
	          }
	        }
	      },
	
	      put: function(charSpec) {
	        var state;
	
	        // If the character specification already exists in a child of the current
	        // state, just return that state.
	        if (state = this.get(charSpec)) { return state; }
	
	        // Make a new state for the character spec
	        state = new $$route$recognizer$$State(charSpec);
	
	        // Insert the new state as a child of the current state
	        this.nextStates.push(state);
	
	        // If this character specification repeats, insert the new state as a child
	        // of itself. Note that this will not trigger an infinite loop because each
	        // transition during recognition consumes a character.
	        if (charSpec.repeat) {
	          state.nextStates.push(state);
	        }
	
	        // Return the new state
	        return state;
	      },
	
	      // Find a list of child states matching the next character
	      match: function(ch) {
	        var nextStates = this.nextStates,
	            child, charSpec, chars;
	
	        var returned = [];
	
	        for (var i=0; i<nextStates.length; i++) {
	          child = nextStates[i];
	
	          charSpec = child.charSpec;
	
	          if (typeof (chars = charSpec.validChars) !== 'undefined') {
	            if (chars.indexOf(ch) !== -1) { returned.push(child); }
	          } else if (typeof (chars = charSpec.invalidChars) !== 'undefined') {
	            if (chars.indexOf(ch) === -1) { returned.push(child); }
	          }
	        }
	
	        return returned;
	      }
	    };
	
	    // Sort the routes by specificity
	    function $$route$recognizer$$sortSolutions(states) {
	      return states.sort(function(a, b) {
	        return b.specificity.val - a.specificity.val;
	      });
	    }
	
	    function $$route$recognizer$$recognizeChar(states, ch) {
	      var nextStates = [];
	
	      for (var i=0, l=states.length; i<l; i++) {
	        var state = states[i];
	
	        nextStates = nextStates.concat(state.match(ch));
	      }
	
	      return nextStates;
	    }
	
	    var $$route$recognizer$$oCreate = Object.create || function(proto) {
	      function F() {}
	      F.prototype = proto;
	      return new F();
	    };
	
	    function $$route$recognizer$$RecognizeResults(queryParams) {
	      this.queryParams = queryParams || {};
	    }
	    $$route$recognizer$$RecognizeResults.prototype = $$route$recognizer$$oCreate({
	      splice: Array.prototype.splice,
	      slice:  Array.prototype.slice,
	      push:   Array.prototype.push,
	      length: 0,
	      queryParams: null
	    });
	
	    function $$route$recognizer$$findHandler(state, path, queryParams) {
	      var handlers = state.handlers, regex = state.regex;
	      var captures = path.match(regex), currentCapture = 1;
	      var result = new $$route$recognizer$$RecognizeResults(queryParams);
	
	      result.length = handlers.length;
	
	      for (var i=0; i<handlers.length; i++) {
	        var handler = handlers[i], names = handler.names, params = {};
	
	        for (var j=0; j<names.length; j++) {
	          params[names[j]] = captures[currentCapture++];
	        }
	
	        result[i] = { handler: handler.handler, params: params, isDynamic: !!names.length };
	      }
	
	      return result;
	    }
	
	    function $$route$recognizer$$decodeQueryParamPart(part) {
	      // http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.1
	      part = part.replace(/\+/gm, '%20');
	      var result;
	      try {
	        result = decodeURIComponent(part);
	      } catch(error) {result = '';}
	      return result;
	    }
	
	    // The main interface
	
	    var $$route$recognizer$$RouteRecognizer = function() {
	      this.rootState = new $$route$recognizer$$State();
	      this.names = {};
	    };
	
	
	    $$route$recognizer$$RouteRecognizer.prototype = {
	      add: function(routes, options) {
	        var currentState = this.rootState, regex = "^",
	            specificity = {},
	            handlers = new Array(routes.length), allSegments = [], name;
	
	        var isEmpty = true;
	
	        for (var i=0; i<routes.length; i++) {
	          var route = routes[i], names = [];
	
	          var segments = $$route$recognizer$$parse(route.path, names, specificity);
	
	          allSegments = allSegments.concat(segments);
	
	          for (var j=0; j<segments.length; j++) {
	            var segment = segments[j];
	
	            if (segment instanceof $$route$recognizer$$EpsilonSegment) { continue; }
	
	            isEmpty = false;
	
	            // Add a "/" for the new segment
	            currentState = currentState.put({ invalidChars: undefined, repeat: false, validChars: "/" });
	            regex += "/";
	
	            // Add a representation of the segment to the NFA and regex
	            currentState = segment.eachChar(currentState);
	            regex += segment.regex();
	          }
	          var handler = { handler: route.handler, names: names };
	          handlers[i] = handler;
	        }
	
	        if (isEmpty) {
	          currentState = currentState.put({ invalidChars: undefined, repeat: false, validChars: "/" });
	          regex += "/";
	        }
	
	        currentState.handlers = handlers;
	        currentState.regex = new RegExp(regex + "$");
	        currentState.specificity = specificity;
	
	        if (name = options && options.as) {
	          this.names[name] = {
	            segments: allSegments,
	            handlers: handlers
	          };
	        }
	      },
	
	      handlersFor: function(name) {
	        var route = this.names[name];
	
	        if (!route) { throw new Error("There is no route named " + name); }
	
	        var result = new Array(route.handlers.length);
	
	        for (var i=0; i<route.handlers.length; i++) {
	          result[i] = route.handlers[i];
	        }
	
	        return result;
	      },
	
	      hasRoute: function(name) {
	        return !!this.names[name];
	      },
	
	      generate: function(name, params) {
	        var route = this.names[name], output = "";
	        if (!route) { throw new Error("There is no route named " + name); }
	
	        var segments = route.segments;
	
	        for (var i=0; i<segments.length; i++) {
	          var segment = segments[i];
	
	          if (segment instanceof $$route$recognizer$$EpsilonSegment) { continue; }
	
	          output += "/";
	          output += segment.generate(params);
	        }
	
	        if (output.charAt(0) !== '/') { output = '/' + output; }
	
	        if (params && params.queryParams) {
	          output += this.generateQueryString(params.queryParams, route.handlers);
	        }
	
	        return output;
	      },
	
	      generateQueryString: function(params, handlers) {
	        var pairs = [];
	        var keys = [];
	        for(var key in params) {
	          if (params.hasOwnProperty(key)) {
	            keys.push(key);
	          }
	        }
	        keys.sort();
	        for (var i = 0; i < keys.length; i++) {
	          key = keys[i];
	          var value = params[key];
	          if (value == null) {
	            continue;
	          }
	          var pair = encodeURIComponent(key);
	          if ($$route$recognizer$$isArray(value)) {
	            for (var j = 0; j < value.length; j++) {
	              var arrayPair = key + '[]' + '=' + encodeURIComponent(value[j]);
	              pairs.push(arrayPair);
	            }
	          } else {
	            pair += "=" + encodeURIComponent(value);
	            pairs.push(pair);
	          }
	        }
	
	        if (pairs.length === 0) { return ''; }
	
	        return "?" + pairs.join("&");
	      },
	
	      parseQueryString: function(queryString) {
	        var pairs = queryString.split("&"), queryParams = {};
	        for(var i=0; i < pairs.length; i++) {
	          var pair      = pairs[i].split('='),
	              key       = $$route$recognizer$$decodeQueryParamPart(pair[0]),
	              keyLength = key.length,
	              isArray = false,
	              value;
	          if (pair.length === 1) {
	            value = 'true';
	          } else {
	            //Handle arrays
	            if (keyLength > 2 && key.slice(keyLength -2) === '[]') {
	              isArray = true;
	              key = key.slice(0, keyLength - 2);
	              if(!queryParams[key]) {
	                queryParams[key] = [];
	              }
	            }
	            value = pair[1] ? $$route$recognizer$$decodeQueryParamPart(pair[1]) : '';
	          }
	          if (isArray) {
	            queryParams[key].push(value);
	          } else {
	            queryParams[key] = value;
	          }
	        }
	        return queryParams;
	      },
	
	      recognize: function(path) {
	        var states = [ this.rootState ],
	            pathLen, i, l, queryStart, queryParams = {},
	            isSlashDropped = false;
	
	        queryStart = path.indexOf('?');
	        if (queryStart !== -1) {
	          var queryString = path.substr(queryStart + 1, path.length);
	          path = path.substr(0, queryStart);
	          queryParams = this.parseQueryString(queryString);
	        }
	
	        path = decodeURI(path);
	
	        if (path.charAt(0) !== "/") { path = "/" + path; }
	
	        pathLen = path.length;
	        if (pathLen > 1 && path.charAt(pathLen - 1) === "/") {
	          path = path.substr(0, pathLen - 1);
	          isSlashDropped = true;
	        }
	
	        for (i=0; i<path.length; i++) {
	          states = $$route$recognizer$$recognizeChar(states, path.charAt(i));
	          if (!states.length) { break; }
	        }
	
	        var solutions = [];
	        for (i=0; i<states.length; i++) {
	          if (states[i].handlers) { solutions.push(states[i]); }
	        }
	
	        states = $$route$recognizer$$sortSolutions(solutions);
	
	        var state = solutions[0];
	
	        if (state && state.handlers) {
	          // if a trailing slash was dropped and a star segment is the last segment
	          // specified, put the trailing slash back
	          if (isSlashDropped && state.regex.source.slice(-5) === "(.+)$") {
	            path = path + "/";
	          }
	          return $$route$recognizer$$findHandler(state, path, queryParams);
	        }
	      }
	    };
	
	    $$route$recognizer$$RouteRecognizer.prototype.map = $$route$recognizer$dsl$$default;
	
	    $$route$recognizer$$RouteRecognizer.VERSION = '0.1.11';
	
	    var $$route$recognizer$$default = $$route$recognizer$$RouteRecognizer;
	
	    /* global define:true module:true window: true */
	    if ( true && __nested_webpack_require_6218__(3)['amd']) {
	      !(__WEBPACK_AMD_DEFINE_RESULT__ = function() { return $$route$recognizer$$default; }.call(exports, __nested_webpack_require_6218__, exports, module), __WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
	    } else if (typeof module !== 'undefined' && module['exports']) {
	      module['exports'] = $$route$recognizer$$default;
	    } else if (typeof this !== 'undefined') {
	      this['RouteRecognizer'] = $$route$recognizer$$default;
	    }
	}).call(this);
	
	//# sourceMappingURL=route-recognizer.js.map
	/* WEBPACK VAR INJECTION */}.call(exports, __nested_webpack_require_6218__(2)(module)))

/***/ },
/* 2 */
/***/ function(module, exports) {

	module.exports = function(module) {
		if(!module.webpackPolyfill) {
			module.deprecate = function() {};
			module.paths = [];
			// module.parent = undefined by default
			module.children = [];
			module.webpackPolyfill = 1;
		}
		return module;
	}


/***/ },
/* 3 */
/***/ function(module, exports) {

	module.exports = function() { throw new Error("define cannot be used indirect"); };


/***/ }
/******/ ])
});
;
//# sourceMappingURL=router.js.map

/***/ }),

/***/ "./src/FilterBuilders/advancedFilterBuilder.ts":
/*!*****************************************************!*\
  !*** ./src/FilterBuilders/advancedFilterBuilder.ts ***!
  \*****************************************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.AdvancedFilterBuilder = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var filterBuilder_1 = __webpack_require__(/*! ./filterBuilder */ "./src/FilterBuilders/filterBuilder.ts");
/**
 * Power BI Advanced filter builder component
 *
 * @export
 * @class AdvancedFilterBuilder
 * @extends {FilterBuilder}
 */
var AdvancedFilterBuilder = /** @class */ (function (_super) {
    __extends(AdvancedFilterBuilder, _super);
    function AdvancedFilterBuilder() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.conditions = [];
        return _this;
    }
    /**
     * Sets And as logical operator for Advanced filter
     *
     * ```javascript
     *
     * const advancedFilterBuilder = new AdvancedFilterBuilder().and();
     * ```
     *
     * @returns {AdvancedFilterBuilder}
     */
    AdvancedFilterBuilder.prototype.and = function () {
        this.logicalOperator = "And";
        return this;
    };
    /**
     * Sets Or as logical operator for Advanced filter
     *
     * ```javascript
     *
     * const advancedFilterBuilder = new AdvancedFilterBuilder().or();
     * ```
     *
     * @returns {AdvancedFilterBuilder}
     */
    AdvancedFilterBuilder.prototype.or = function () {
        this.logicalOperator = "Or";
        return this;
    };
    /**
     * Adds a condition in Advanced filter
     *
     * ```javascript
     *
     * // Add two conditions
     * const advancedFilterBuilder = new AdvancedFilterBuilder().addCondition("Contains", "Wash").addCondition("Contains", "Park");
     * ```
     *
     * @returns {AdvancedFilterBuilder}
     */
    AdvancedFilterBuilder.prototype.addCondition = function (operator, value) {
        var condition = {
            operator: operator,
            value: value
        };
        this.conditions.push(condition);
        return this;
    };
    /**
     * Creates Advanced filter
     *
     * ```javascript
     *
     * const advancedFilterBuilder = new AdvancedFilterBuilder().build();
     * ```
     *
     * @returns {AdvancedFilter}
     */
    AdvancedFilterBuilder.prototype.build = function () {
        var advancedFilter = new powerbi_models_1.AdvancedFilter(this.target, this.logicalOperator, this.conditions);
        return advancedFilter;
    };
    return AdvancedFilterBuilder;
}(filterBuilder_1.FilterBuilder));
exports.AdvancedFilterBuilder = AdvancedFilterBuilder;


/***/ }),

/***/ "./src/FilterBuilders/basicFilterBuilder.ts":
/*!**************************************************!*\
  !*** ./src/FilterBuilders/basicFilterBuilder.ts ***!
  \**************************************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.BasicFilterBuilder = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var filterBuilder_1 = __webpack_require__(/*! ./filterBuilder */ "./src/FilterBuilders/filterBuilder.ts");
/**
 * Power BI Basic filter builder component
 *
 * @export
 * @class BasicFilterBuilder
 * @extends {FilterBuilder}
 */
var BasicFilterBuilder = /** @class */ (function (_super) {
    __extends(BasicFilterBuilder, _super);
    function BasicFilterBuilder() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.isRequireSingleSelection = false;
        return _this;
    }
    /**
     * Sets In as operator for Basic filter
     *
     * ```javascript
     *
     * const basicFilterBuilder = new BasicFilterBuilder().in([values]);
     * ```
     *
     * @returns {BasicFilterBuilder}
     */
    BasicFilterBuilder.prototype.in = function (values) {
        this.operator = "In";
        this.values = values;
        return this;
    };
    /**
     * Sets NotIn as operator for Basic filter
     *
     * ```javascript
     *
     * const basicFilterBuilder = new BasicFilterBuilder().notIn([values]);
     * ```
     *
     * @returns {BasicFilterBuilder}
     */
    BasicFilterBuilder.prototype.notIn = function (values) {
        this.operator = "NotIn";
        this.values = values;
        return this;
    };
    /**
     * Sets All as operator for Basic filter
     *
     * ```javascript
     *
     * const basicFilterBuilder = new BasicFilterBuilder().all();
     * ```
     *
     * @returns {BasicFilterBuilder}
     */
    BasicFilterBuilder.prototype.all = function () {
        this.operator = "All";
        this.values = [];
        return this;
    };
    /**
     * Sets required single selection property for Basic filter
     *
     * ```javascript
     *
     * const basicFilterBuilder = new BasicFilterBuilder().requireSingleSelection(isRequireSingleSelection);
     * ```
     *
     * @returns {BasicFilterBuilder}
     */
    BasicFilterBuilder.prototype.requireSingleSelection = function (isRequireSingleSelection) {
        if (isRequireSingleSelection === void 0) { isRequireSingleSelection = false; }
        this.isRequireSingleSelection = isRequireSingleSelection;
        return this;
    };
    /**
     * Creates Basic filter
     *
     * ```javascript
     *
     * const basicFilterBuilder = new BasicFilterBuilder().build();
     * ```
     *
     * @returns {BasicFilter}
     */
    BasicFilterBuilder.prototype.build = function () {
        var basicFilter = new powerbi_models_1.BasicFilter(this.target, this.operator, this.values);
        basicFilter.requireSingleSelection = this.isRequireSingleSelection;
        return basicFilter;
    };
    return BasicFilterBuilder;
}(filterBuilder_1.FilterBuilder));
exports.BasicFilterBuilder = BasicFilterBuilder;


/***/ }),

/***/ "./src/FilterBuilders/filterBuilder.ts":
/*!*********************************************!*\
  !*** ./src/FilterBuilders/filterBuilder.ts ***!
  \*********************************************/
/***/ ((__unused_webpack_module, exports) => {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.FilterBuilder = void 0;
/**
 * Generic filter builder for BasicFilter, AdvancedFilter, RelativeDate, RelativeTime and TopN
 *
 * @class
 */
var FilterBuilder = /** @class */ (function () {
    function FilterBuilder() {
    }
    /**
     * Sets target property for filter with target object
     *
     * ```javascript
     * const target = {
     *  table: 'table1',
     *  column: 'column1'
     * };
     *
     * const filterBuilder = new FilterBuilder().withTargetObject(target);
     * ```
     *
     * @returns {FilterBuilder}
     */
    FilterBuilder.prototype.withTargetObject = function (target) {
        this.target = target;
        return this;
    };
    /**
     * Sets target property for filter with column target object
     *
     * ```
     * const filterBuilder = new FilterBuilder().withColumnTarget(tableName, columnName);
     * ```
     *
     * @returns {FilterBuilder}
     */
    FilterBuilder.prototype.withColumnTarget = function (tableName, columnName) {
        this.target = { table: tableName, column: columnName };
        return this;
    };
    /**
     * Sets target property for filter with measure target object
     *
     * ```
     * const filterBuilder = new FilterBuilder().withMeasureTarget(tableName, measure);
     * ```
     *
     * @returns {FilterBuilder}
     */
    FilterBuilder.prototype.withMeasureTarget = function (tableName, measure) {
        this.target = { table: tableName, measure: measure };
        return this;
    };
    /**
     * Sets target property for filter with hierarchy level target object
     *
     * ```
     * const filterBuilder = new FilterBuilder().withHierarchyLevelTarget(tableName, hierarchy, hierarchyLevel);
     * ```
     *
     * @returns {FilterBuilder}
     */
    FilterBuilder.prototype.withHierarchyLevelTarget = function (tableName, hierarchy, hierarchyLevel) {
        this.target = { table: tableName, hierarchy: hierarchy, hierarchyLevel: hierarchyLevel };
        return this;
    };
    /**
     * Sets target property for filter with column aggregation target object
     *
     * ```
     * const filterBuilder = new FilterBuilder().withColumnAggregation(tableName, columnName, aggregationFunction);
     * ```
     *
     * @returns {FilterBuilder}
     */
    FilterBuilder.prototype.withColumnAggregation = function (tableName, columnName, aggregationFunction) {
        this.target = { table: tableName, column: columnName, aggregationFunction: aggregationFunction };
        return this;
    };
    /**
     * Sets target property for filter with hierarchy level aggregation target object
     *
     * ```
     * const filterBuilder = new FilterBuilder().withHierarchyLevelAggregationTarget(tableName, hierarchy, hierarchyLevel, aggregationFunction);
     * ```
     *
     * @returns {FilterBuilder}
     */
    FilterBuilder.prototype.withHierarchyLevelAggregationTarget = function (tableName, hierarchy, hierarchyLevel, aggregationFunction) {
        this.target = { table: tableName, hierarchy: hierarchy, hierarchyLevel: hierarchyLevel, aggregationFunction: aggregationFunction };
        return this;
    };
    return FilterBuilder;
}());
exports.FilterBuilder = FilterBuilder;


/***/ }),

/***/ "./src/FilterBuilders/index.ts":
/*!*************************************!*\
  !*** ./src/FilterBuilders/index.ts ***!
  \*************************************/
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.RelativeTimeFilterBuilder = exports.RelativeDateFilterBuilder = exports.TopNFilterBuilder = exports.AdvancedFilterBuilder = exports.BasicFilterBuilder = void 0;
var basicFilterBuilder_1 = __webpack_require__(/*! ./basicFilterBuilder */ "./src/FilterBuilders/basicFilterBuilder.ts");
Object.defineProperty(exports, "BasicFilterBuilder", ({ enumerable: true, get: function () { return basicFilterBuilder_1.BasicFilterBuilder; } }));
var advancedFilterBuilder_1 = __webpack_require__(/*! ./advancedFilterBuilder */ "./src/FilterBuilders/advancedFilterBuilder.ts");
Object.defineProperty(exports, "AdvancedFilterBuilder", ({ enumerable: true, get: function () { return advancedFilterBuilder_1.AdvancedFilterBuilder; } }));
var topNFilterBuilder_1 = __webpack_require__(/*! ./topNFilterBuilder */ "./src/FilterBuilders/topNFilterBuilder.ts");
Object.defineProperty(exports, "TopNFilterBuilder", ({ enumerable: true, get: function () { return topNFilterBuilder_1.TopNFilterBuilder; } }));
var relativeDateFilterBuilder_1 = __webpack_require__(/*! ./relativeDateFilterBuilder */ "./src/FilterBuilders/relativeDateFilterBuilder.ts");
Object.defineProperty(exports, "RelativeDateFilterBuilder", ({ enumerable: true, get: function () { return relativeDateFilterBuilder_1.RelativeDateFilterBuilder; } }));
var relativeTimeFilterBuilder_1 = __webpack_require__(/*! ./relativeTimeFilterBuilder */ "./src/FilterBuilders/relativeTimeFilterBuilder.ts");
Object.defineProperty(exports, "RelativeTimeFilterBuilder", ({ enumerable: true, get: function () { return relativeTimeFilterBuilder_1.RelativeTimeFilterBuilder; } }));


/***/ }),

/***/ "./src/FilterBuilders/relativeDateFilterBuilder.ts":
/*!*********************************************************!*\
  !*** ./src/FilterBuilders/relativeDateFilterBuilder.ts ***!
  \*********************************************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.RelativeDateFilterBuilder = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var filterBuilder_1 = __webpack_require__(/*! ./filterBuilder */ "./src/FilterBuilders/filterBuilder.ts");
/**
 * Power BI Relative Date filter builder component
 *
 * @export
 * @class RelativeDateFilterBuilder
 * @extends {FilterBuilder}
 */
var RelativeDateFilterBuilder = /** @class */ (function (_super) {
    __extends(RelativeDateFilterBuilder, _super);
    function RelativeDateFilterBuilder() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.isTodayIncluded = true;
        return _this;
    }
    /**
     * Sets inLast as operator for Relative Date filter
     *
     * ```javascript
     *
     * const relativeDateFilterBuilder = new RelativeDateFilterBuilder().inLast(timeUnitsCount, timeUnitType);
     * ```
     *
     * @param {number} timeUnitsCount - The amount of time units
     * @param {RelativeDateFilterTimeUnit} timeUnitType - Defines the unit of time the filter is using
     * @returns {RelativeDateFilterBuilder}
     */
    RelativeDateFilterBuilder.prototype.inLast = function (timeUnitsCount, timeUnitType) {
        this.operator = powerbi_models_1.RelativeDateOperators.InLast;
        this.timeUnitsCount = timeUnitsCount;
        this.timeUnitType = timeUnitType;
        return this;
    };
    /**
     * Sets inThis as operator for Relative Date filter
     *
     * ```javascript
     *
     * const relativeDateFilterBuilder = new RelativeDateFilterBuilder().inThis(timeUnitsCount, timeUnitType);
     * ```
     *
     * @param {number} timeUnitsCount - The amount of time units
     * @param {RelativeDateFilterTimeUnit} timeUnitType - Defines the unit of time the filter is using
     * @returns {RelativeDateFilterBuilder}
     */
    RelativeDateFilterBuilder.prototype.inThis = function (timeUnitsCount, timeUnitType) {
        this.operator = powerbi_models_1.RelativeDateOperators.InThis;
        this.timeUnitsCount = timeUnitsCount;
        this.timeUnitType = timeUnitType;
        return this;
    };
    /**
     * Sets inNext as operator for Relative Date filter
     *
     * ```javascript
     *
     * const relativeDateFilterBuilder = new RelativeDateFilterBuilder().inNext(timeUnitsCount, timeUnitType);
     * ```
     *
     * @param {number} timeUnitsCount - The amount of time units
     * @param {RelativeDateFilterTimeUnit} timeUnitType - Defines the unit of time the filter is using
     * @returns {RelativeDateFilterBuilder}
     */
    RelativeDateFilterBuilder.prototype.inNext = function (timeUnitsCount, timeUnitType) {
        this.operator = powerbi_models_1.RelativeDateOperators.InNext;
        this.timeUnitsCount = timeUnitsCount;
        this.timeUnitType = timeUnitType;
        return this;
    };
    /**
     * Sets includeToday for Relative Date filter
     *
     * ```javascript
     *
     * const relativeDateFilterBuilder = new RelativeDateFilterBuilder().includeToday(includeToday);
     * ```
     *
     * @param {boolean} includeToday - Denotes if today is included or not
     * @returns {RelativeDateFilterBuilder}
     */
    RelativeDateFilterBuilder.prototype.includeToday = function (includeToday) {
        this.isTodayIncluded = includeToday;
        return this;
    };
    /**
     * Creates Relative Date filter
     *
     * ```javascript
     *
     * const relativeDateFilterBuilder = new RelativeDateFilterBuilder().build();
     * ```
     *
     * @returns {RelativeDateFilter}
     */
    RelativeDateFilterBuilder.prototype.build = function () {
        var relativeDateFilter = new powerbi_models_1.RelativeDateFilter(this.target, this.operator, this.timeUnitsCount, this.timeUnitType, this.isTodayIncluded);
        return relativeDateFilter;
    };
    return RelativeDateFilterBuilder;
}(filterBuilder_1.FilterBuilder));
exports.RelativeDateFilterBuilder = RelativeDateFilterBuilder;


/***/ }),

/***/ "./src/FilterBuilders/relativeTimeFilterBuilder.ts":
/*!*********************************************************!*\
  !*** ./src/FilterBuilders/relativeTimeFilterBuilder.ts ***!
  \*********************************************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.RelativeTimeFilterBuilder = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var filterBuilder_1 = __webpack_require__(/*! ./filterBuilder */ "./src/FilterBuilders/filterBuilder.ts");
/**
 * Power BI Relative Time filter builder component
 *
 * @export
 * @class RelativeTimeFilterBuilder
 * @extends {FilterBuilder}
 */
var RelativeTimeFilterBuilder = /** @class */ (function (_super) {
    __extends(RelativeTimeFilterBuilder, _super);
    function RelativeTimeFilterBuilder() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    /**
     * Sets inLast as operator for Relative Time filter
     *
     * ```javascript
     *
     * const relativeTimeFilterBuilder = new RelativeTimeFilterBuilder().inLast(timeUnitsCount, timeUnitType);
     * ```
     *
     * @param {number} timeUnitsCount - The amount of time units
     * @param {RelativeDateFilterTimeUnit} timeUnitType - Defines the unit of time the filter is using
     * @returns {RelativeTimeFilterBuilder}
     */
    RelativeTimeFilterBuilder.prototype.inLast = function (timeUnitsCount, timeUnitType) {
        this.operator = powerbi_models_1.RelativeDateOperators.InLast;
        this.timeUnitsCount = timeUnitsCount;
        this.timeUnitType = timeUnitType;
        return this;
    };
    /**
     * Sets inThis as operator for Relative Time filter
     *
     * ```javascript
     *
     * const relativeTimeFilterBuilder = new RelativeTimeFilterBuilder().inThis(timeUnitsCount, timeUnitType);
     * ```
     *
     * @param {number} timeUnitsCount - The amount of time units
     * @param {RelativeDateFilterTimeUnit} timeUnitType - Defines the unit of time the filter is using
     * @returns {RelativeTimeFilterBuilder}
     */
    RelativeTimeFilterBuilder.prototype.inThis = function (timeUnitsCount, timeUnitType) {
        this.operator = powerbi_models_1.RelativeDateOperators.InThis;
        this.timeUnitsCount = timeUnitsCount;
        this.timeUnitType = timeUnitType;
        return this;
    };
    /**
     * Sets inNext as operator for Relative Time filter
     *
     * ```javascript
     *
     * const relativeTimeFilterBuilder = new RelativeTimeFilterBuilder().inNext(timeUnitsCount, timeUnitType);
     * ```
     *
     * @param {number} timeUnitsCount - The amount of time units
     * @param {RelativeDateFilterTimeUnit} timeUnitType - Defines the unit of time the filter is using
     * @returns {RelativeTimeFilterBuilder}
     */
    RelativeTimeFilterBuilder.prototype.inNext = function (timeUnitsCount, timeUnitType) {
        this.operator = powerbi_models_1.RelativeDateOperators.InNext;
        this.timeUnitsCount = timeUnitsCount;
        this.timeUnitType = timeUnitType;
        return this;
    };
    /**
     * Creates Relative Time filter
     *
     * ```javascript
     *
     * const relativeTimeFilterBuilder = new RelativeTimeFilterBuilder().build();
     * ```
     *
     * @returns {RelativeTimeFilter}
     */
    RelativeTimeFilterBuilder.prototype.build = function () {
        var relativeTimeFilter = new powerbi_models_1.RelativeTimeFilter(this.target, this.operator, this.timeUnitsCount, this.timeUnitType);
        return relativeTimeFilter;
    };
    return RelativeTimeFilterBuilder;
}(filterBuilder_1.FilterBuilder));
exports.RelativeTimeFilterBuilder = RelativeTimeFilterBuilder;


/***/ }),

/***/ "./src/FilterBuilders/topNFilterBuilder.ts":
/*!*************************************************!*\
  !*** ./src/FilterBuilders/topNFilterBuilder.ts ***!
  \*************************************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.TopNFilterBuilder = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var filterBuilder_1 = __webpack_require__(/*! ./filterBuilder */ "./src/FilterBuilders/filterBuilder.ts");
/**
 * Power BI Top N filter builder component
 *
 * @export
 * @class TopNFilterBuilder
 * @extends {FilterBuilder}
 */
var TopNFilterBuilder = /** @class */ (function (_super) {
    __extends(TopNFilterBuilder, _super);
    function TopNFilterBuilder() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    /**
     * Sets Top as operator for Top N filter
     *
     * ```javascript
     *
     * const topNFilterBuilder = new TopNFilterBuilder().top(itemCount);
     * ```
     *
     * @returns {TopNFilterBuilder}
     */
    TopNFilterBuilder.prototype.top = function (itemCount) {
        this.operator = "Top";
        this.itemCount = itemCount;
        return this;
    };
    /**
     * Sets Bottom as operator for Top N filter
     *
     * ```javascript
     *
     * const topNFilterBuilder = new TopNFilterBuilder().bottom(itemCount);
     * ```
     *
     * @returns {TopNFilterBuilder}
     */
    TopNFilterBuilder.prototype.bottom = function (itemCount) {
        this.operator = "Bottom";
        this.itemCount = itemCount;
        return this;
    };
    /**
     * Sets order by for Top N filter
     *
     * ```javascript
     *
     * const topNFilterBuilder = new TopNFilterBuilder().orderByTarget(target);
     * ```
     *
     * @returns {TopNFilterBuilder}
     */
    TopNFilterBuilder.prototype.orderByTarget = function (target) {
        this.orderByTargetValue = target;
        return this;
    };
    /**
     * Creates Top N filter
     *
     * ```javascript
     *
     * const topNFilterBuilder = new TopNFilterBuilder().build();
     * ```
     *
     * @returns {TopNFilter}
     */
    TopNFilterBuilder.prototype.build = function () {
        var topNFilter = new powerbi_models_1.TopNFilter(this.target, this.operator, this.itemCount, this.orderByTargetValue);
        return topNFilter;
    };
    return TopNFilterBuilder;
}(filterBuilder_1.FilterBuilder));
exports.TopNFilterBuilder = TopNFilterBuilder;


/***/ }),

/***/ "./src/bookmarksManager.ts":
/*!*********************************!*\
  !*** ./src/bookmarksManager.ts ***!
  \*********************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.BookmarksManager = void 0;
var util_1 = __webpack_require__(/*! ./util */ "./src/util.ts");
var errors_1 = __webpack_require__(/*! ./errors */ "./src/errors.ts");
/**
 * Manages report bookmarks.
 *
 * @export
 * @class BookmarksManager
 * @implements {IBookmarksManager}
 */
var BookmarksManager = /** @class */ (function () {
    /**
     * @hidden
     */
    function BookmarksManager(service, config, iframe) {
        this.service = service;
        this.config = config;
        this.iframe = iframe;
    }
    /**
     * Gets bookmarks that are defined in the report.
     *
     * ```javascript
     * // Gets bookmarks that are defined in the report
     * bookmarksManager.getBookmarks()
     *   .then(bookmarks => {
     *     ...
     *   });
     * ```
     *
     * @returns {Promise<IReportBookmark[]>}
     */
    BookmarksManager.prototype.getBookmarks = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_1;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.get("/report/bookmarks", { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_1 = _a.sent();
                        throw response_1.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Apply bookmark by name.
     *
     * ```javascript
     * bookmarksManager.apply(bookmarkName)
     * ```
     *
     * @param {string} bookmarkName The name of the bookmark to be applied
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    BookmarksManager.prototype.apply = function (bookmarkName) {
        return __awaiter(this, void 0, void 0, function () {
            var request, response_2;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        request = {
                            name: bookmarkName
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post("/report/bookmarks/applyByName", request, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_2 = _a.sent();
                        throw response_2.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Play bookmarks: Enter or Exit bookmarks presentation mode.
     *
     * ```javascript
     * // Enter presentation mode.
     * bookmarksManager.play(BookmarksPlayMode.Presentation)
     * ```
     *
     * @param {BookmarksPlayMode} playMode Play mode can be either `Presentation` or `Off`
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    BookmarksManager.prototype.play = function (playMode) {
        return __awaiter(this, void 0, void 0, function () {
            var playBookmarkRequest, response_3;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        playBookmarkRequest = {
                            playMode: playMode
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post("/report/bookmarks/play", playBookmarkRequest, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_3 = _a.sent();
                        throw response_3.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Capture bookmark from current state.
     *
     * ```javascript
     * bookmarksManager.capture(options)
     * ```
     *
     * @param {ICaptureBookmarkOptions} [options] Options for bookmark capturing
     * @returns {Promise<IReportBookmark>}
     */
    BookmarksManager.prototype.capture = function (options) {
        return __awaiter(this, void 0, void 0, function () {
            var request, response, response_4;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        request = {
                            options: options || {}
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post("/report/bookmarks/capture", request, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_4 = _a.sent();
                        throw response_4.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Apply bookmark state.
     *
     * ```javascript
     * bookmarksManager.applyState(bookmarkState)
     * ```
     *
     * @param {string} state A base64 bookmark state to be applied
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    BookmarksManager.prototype.applyState = function (state) {
        return __awaiter(this, void 0, void 0, function () {
            var request, response_5;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        request = {
                            state: state
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post("/report/bookmarks/applyState", request, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_5 = _a.sent();
                        throw response_5.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    return BookmarksManager;
}());
exports.BookmarksManager = BookmarksManager;


/***/ }),

/***/ "./src/config.ts":
/*!***********************!*\
  !*** ./src/config.ts ***!
  \***********************/
/***/ ((__unused_webpack_module, exports) => {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
Object.defineProperty(exports, "__esModule", ({ value: true }));
/** @ignore */ /** */
var config = {
    version: '2.22.2',
    type: 'js'
};
exports["default"] = config;


/***/ }),

/***/ "./src/create.ts":
/*!***********************!*\
  !*** ./src/create.ts ***!
  \***********************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.Create = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var embed_1 = __webpack_require__(/*! ./embed */ "./src/embed.ts");
var utils = __webpack_require__(/*! ./util */ "./src/util.ts");
/**
 * A Power BI Report creator component
 *
 * @export
 * @class Create
 * @extends {Embed}
 */
var Create = /** @class */ (function (_super) {
    __extends(Create, _super);
    /*
     * @hidden
     */
    function Create(service, element, config, phasedRender, isBootstrap) {
        return _super.call(this, service, element, config, /* iframe */ undefined, phasedRender, isBootstrap) || this;
    }
    /**
     * Gets the dataset ID from the first available location: createConfig or embed url.
     *
     * @returns {string}
     */
    Create.prototype.getId = function () {
        var datasetId = (this.createConfig && this.createConfig.datasetId) ? this.createConfig.datasetId : Create.findIdFromEmbedUrl(this.config.embedUrl);
        if (typeof datasetId !== 'string' || datasetId.length === 0) {
            throw new Error('Dataset id is required, but it was not found. You must provide an id either as part of embed configuration.');
        }
        return datasetId;
    };
    /**
     * Validate create report configuration.
     */
    Create.prototype.validate = function (config) {
        return (0, powerbi_models_1.validateCreateReport)(config);
    };
    /**
     * Handle config changes.
     *
     * @hidden
     * @returns {void}
     */
    Create.prototype.configChanged = function (isBootstrap) {
        if (isBootstrap) {
            return;
        }
        var config = this.config;
        this.createConfig = {
            accessToken: config.accessToken,
            datasetId: config.datasetId || this.getId(),
            groupId: config.groupId,
            settings: config.settings,
            tokenType: config.tokenType,
            theme: config.theme
        };
    };
    /**
     * @hidden
     * @returns {string}
     */
    Create.prototype.getDefaultEmbedUrlEndpoint = function () {
        return "reportEmbed";
    };
    /**
     * checks if the report is saved.
     *
     * ```javascript
     * report.isSaved()
     * ```
     *
     * @returns {Promise<boolean>}
     */
    Create.prototype.isSaved = function () {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, utils.isSavedInternal(this.service.hpm, this.config.uniqueId, this.iframe.contentWindow)];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * Adds the ability to get datasetId from url.
     * (e.g. http://embedded.powerbi.com/appTokenReportEmbed?datasetId=854846ed-2106-4dc2-bc58-eb77533bf2f1).
     *
     * By extracting the ID we can ensure that the ID is always explicitly provided as part of the create configuration.
     *
     * @static
     * @param {string} url
     * @returns {string}
     * @hidden
     */
    Create.findIdFromEmbedUrl = function (url) {
        var datasetIdRegEx = /datasetId="?([^&]+)"?/;
        var datasetIdMatch = url.match(datasetIdRegEx);
        var datasetId;
        if (datasetIdMatch) {
            datasetId = datasetIdMatch[1];
        }
        return datasetId;
    };
    /**
     * Sends create configuration data.
     *
     * ```javascript
     * create ({
     *   datasetId: '5dac7a4a-4452-46b3-99f6-a25915e0fe55',
     *   accessToken: 'eyJ0eXA ... TaE2rTSbmg',
     * ```
     *
     * @hidden
     * @returns {Promise<void>}
     */
    Create.prototype.create = function () {
        var _a;
        return __awaiter(this, void 0, void 0, function () {
            var errors, headers, response, response_1;
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        errors = (0, powerbi_models_1.validateCreateReport)(this.createConfig);
                        if (errors) {
                            throw errors;
                        }
                        _b.label = 1;
                    case 1:
                        _b.trys.push([1, 3, , 4]);
                        headers = {
                            uid: this.config.uniqueId,
                            sdkSessionId: this.service.getSdkSessionId()
                        };
                        if (!!((_a = this.eventHooks) === null || _a === void 0 ? void 0 : _a.accessTokenProvider)) {
                            headers.tokenProviderSupplied = true;
                        }
                        return [4 /*yield*/, this.service.hpm.post("/report/create", this.createConfig, headers, this.iframe.contentWindow)];
                    case 2:
                        response = _b.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_1 = _b.sent();
                        throw response_1.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    return Create;
}(embed_1.Embed));
exports.Create = Create;


/***/ }),

/***/ "./src/dashboard.ts":
/*!**************************!*\
  !*** ./src/dashboard.ts ***!
  \**************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.Dashboard = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var embed_1 = __webpack_require__(/*! ./embed */ "./src/embed.ts");
/**
 * A Power BI Dashboard embed component
 *
 * @export
 * @class Dashboard
 * @extends {Embed}
 * @implements {IDashboardNode}
 */
var Dashboard = /** @class */ (function (_super) {
    __extends(Dashboard, _super);
    /**
     * Creates an instance of a Power BI Dashboard.
     *
     * @param {service.Service} service
     * @hidden
     * @param {HTMLElement} element
     */
    function Dashboard(service, element, config, phasedRender, isBootstrap) {
        var _this = _super.call(this, service, element, config, /* iframe */ undefined, phasedRender, isBootstrap) || this;
        _this.loadPath = "/dashboard/load";
        _this.phasedLoadPath = "/dashboard/prepare";
        Array.prototype.push.apply(_this.allowedEvents, Dashboard.allowedEvents);
        return _this;
    }
    /**
     * This adds backwards compatibility for older config which used the dashboardId query param to specify dashboard id.
     * E.g. https://powerbi-df.analysis-df.windows.net/dashboardEmbedHost?dashboardId=e9363c62-edb6-4eac-92d3-2199c5ca2a9e
     *
     * By extracting the id we can ensure id is always explicitly provided as part of the load configuration.
     *
     * @hidden
     * @static
     * @param {string} url
     * @returns {string}
     */
    Dashboard.findIdFromEmbedUrl = function (url) {
        var dashboardIdRegEx = /dashboardId="?([^&]+)"?/;
        var dashboardIdMatch = url.match(dashboardIdRegEx);
        var dashboardId;
        if (dashboardIdMatch) {
            dashboardId = dashboardIdMatch[1];
        }
        return dashboardId;
    };
    /**
     * Get dashboard id from first available location: options, attribute, embed url.
     *
     * @returns {string}
     */
    Dashboard.prototype.getId = function () {
        var config = this.config;
        var dashboardId = config.id || this.element.getAttribute(Dashboard.dashboardIdAttribute) || Dashboard.findIdFromEmbedUrl(config.embedUrl);
        if (typeof dashboardId !== 'string' || dashboardId.length === 0) {
            throw new Error("Dashboard id is required, but it was not found. You must provide an id either as part of embed configuration or as attribute '".concat(Dashboard.dashboardIdAttribute, "'."));
        }
        return dashboardId;
    };
    /**
     * Validate load configuration.
     *
     * @hidden
     */
    Dashboard.prototype.validate = function (baseConfig) {
        var config = baseConfig;
        var error = (0, powerbi_models_1.validateDashboardLoad)(config);
        return error ? error : this.validatePageView(config.pageView);
    };
    /**
     * Handle config changes.
     *
     * @hidden
     * @returns {void}
     */
    Dashboard.prototype.configChanged = function (isBootstrap) {
        if (isBootstrap) {
            return;
        }
        // Populate dashboard id into config object.
        this.config.id = this.getId();
    };
    /**
     * @hidden
     * @returns {string}
     */
    Dashboard.prototype.getDefaultEmbedUrlEndpoint = function () {
        return "dashboardEmbed";
    };
    /**
     * Validate that pageView has a legal value: if page view is defined it must have one of the values defined in PageView
     *
     * @hidden
     */
    Dashboard.prototype.validatePageView = function (pageView) {
        if (pageView && pageView !== "fitToWidth" && pageView !== "oneColumn" && pageView !== "actualSize") {
            return [{ message: "pageView must be one of the followings: fitToWidth, oneColumn, actualSize" }];
        }
    };
    /** @hidden */
    Dashboard.allowedEvents = ["tileClicked", "error"];
    /** @hidden */
    Dashboard.dashboardIdAttribute = 'powerbi-dashboard-id';
    /** @hidden */
    Dashboard.typeAttribute = 'powerbi-type';
    /** @hidden */
    Dashboard.type = "Dashboard";
    return Dashboard;
}(embed_1.Embed));
exports.Dashboard = Dashboard;


/***/ }),

/***/ "./src/embed.ts":
/*!**********************!*\
  !*** ./src/embed.ts ***!
  \**********************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.Embed = void 0;
var models = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var sdkConfig = __webpack_require__(/*! ./config */ "./src/config.ts");
var errors_1 = __webpack_require__(/*! ./errors */ "./src/errors.ts");
var util_1 = __webpack_require__(/*! ./util */ "./src/util.ts");
/**
 * Base class for all Power BI embed components
 *
 * @export
 * @abstract
 * @hidden
 * @class Embed
 */
var Embed = /** @class */ (function () {
    /**
     * Creates an instance of Embed.
     *
     * Note: there is circular reference between embeds and the service, because
     * the service has a list of all embeds on the host page, and each embed has a reference to the service that created it.
     *
     * @param {service.Service} service
     * @param {HTMLElement} element
     * @param {IEmbedConfigurationBase} config
     * @hidden
     */
    function Embed(service, element, config, iframe, phasedRender, isBootstrap) {
        /** @hidden */
        this.allowedEvents = [];
        if ((0, util_1.autoAuthInEmbedUrl)(config.embedUrl)) {
            throw new Error(errors_1.EmbedUrlNotSupported);
        }
        Array.prototype.push.apply(this.allowedEvents, Embed.allowedEvents);
        this.eventHandlers = [];
        this.service = service;
        this.element = element;
        this.iframe = iframe;
        this.iframeLoaded = false;
        this.embedtype = config.type.toLowerCase();
        this.commands = [];
        this.groups = [];
        this.populateConfig(config, isBootstrap);
        if ((0, util_1.isCreate)(this.embedtype)) {
            this.setIframe(false /* set EventListener to call create() on 'load' event*/, phasedRender, isBootstrap);
        }
        else {
            this.setIframe(true /* set EventListener to call load() on 'load' event*/, phasedRender, isBootstrap);
        }
    }
    /**
     * Create is not supported by default
     *
     * @hidden
     * @returns {Promise<void>}
     */
    Embed.prototype.create = function () {
        throw new Error("no create support");
    };
    /**
     * Saves Report.
     *
     * @returns {Promise<void>}
     */
    Embed.prototype.save = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_1;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.service.hpm.post('/report/save', null, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_1 = _a.sent();
                        throw response_1.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * SaveAs Report.
     *
     * @returns {Promise<void>}
     */
    Embed.prototype.saveAs = function (saveAsParameters) {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_2;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.service.hpm.post('/report/saveAs', saveAsParameters, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_2 = _a.sent();
                        throw response_2.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Get the correlationId for the current embed session.
     *
     * ```javascript
     * // Get the correlationId for the current embed session
     * report.getCorrelationId()
     *   .then(correlationId => {
     *     ...
     *   });
     * ```
     *
     * @returns {Promise<string>}
     */
    Embed.prototype.getCorrelationId = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_3;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.service.hpm.get("/getCorrelationId", { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_3 = _a.sent();
                        throw response_3.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Sends load configuration data.
     *
     * ```javascript
     * report.load({
     *   type: 'report',
     *   id: '5dac7a4a-4452-46b3-99f6-a25915e0fe55',
     *   accessToken: 'eyJ0eXA ... TaE2rTSbmg',
     *   settings: {
     *     navContentPaneEnabled: false
     *   },
     *   pageName: "DefaultPage",
     *   filters: [
     *     {
     *        ...  DefaultReportFilter ...
     *     }
     *   ]
     * })
     *   .catch(error => { ... });
     * ```
     *
     * @hidden
     * @param {models.ILoadConfiguration} config
     * @param {boolean} phasedRender
     * @returns {Promise<void>}
     */
    Embed.prototype.load = function (phasedRender) {
        var _a;
        return __awaiter(this, void 0, void 0, function () {
            var path, headers, timeNow, response, response_4;
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        if (!this.config.accessToken) {
                            console.debug("Power BI SDK iframe is loaded but powerbi.embed is not called yet.");
                            return [2 /*return*/];
                        }
                        if (!this.iframeLoaded) {
                            console.debug("Power BI SDK is trying to post /report/load before iframe is ready.");
                            return [2 /*return*/];
                        }
                        path = phasedRender && this.config.type === 'report' ? this.phasedLoadPath : this.loadPath;
                        headers = {
                            uid: this.config.uniqueId,
                            sdkSessionId: this.service.getSdkSessionId(),
                            bootstrapped: this.config.bootstrapped,
                            sdkVersion: sdkConfig.default.version
                        };
                        if (!!((_a = this.eventHooks) === null || _a === void 0 ? void 0 : _a.accessTokenProvider)) {
                            headers.tokenProviderSupplied = true;
                        }
                        timeNow = new Date();
                        if (this.lastLoadRequest && (0, util_1.getTimeDiffInMilliseconds)(this.lastLoadRequest, timeNow) < 100) {
                            console.debug("Power BI SDK sent more than two /report/load requests in the last 100ms interval.");
                            return [2 /*return*/];
                        }
                        this.lastLoadRequest = timeNow;
                        _b.label = 1;
                    case 1:
                        _b.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post(path, this.config, headers, this.iframe.contentWindow)];
                    case 2:
                        response = _b.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_4 = _b.sent();
                        throw response_4.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Removes one or more event handlers from the list of handlers.
     * If a reference to the existing handle function is specified, remove the specific handler.
     * If the handler is not specified, remove all handlers for the event name specified.
     *
     * ```javascript
     * report.off('pageChanged')
     *
     * or
     *
     * const logHandler = function (event) {
     *    console.log(event);
     * };
     *
     * report.off('pageChanged', logHandler);
     * ```
     *
     * @template T
     * @param {string} eventName
     * @param {IEventHandler<T>} [handler]
     */
    Embed.prototype.off = function (eventName, handler) {
        var _this = this;
        var fakeEvent = { name: eventName, type: null, id: null, value: null };
        if (handler) {
            (0, util_1.remove)(function (eventHandler) { return eventHandler.test(fakeEvent) && (eventHandler.handle === handler); }, this.eventHandlers);
            this.element.removeEventListener(eventName, handler);
        }
        else {
            var eventHandlersToRemove = this.eventHandlers
                .filter(function (eventHandler) { return eventHandler.test(fakeEvent); });
            eventHandlersToRemove
                .forEach(function (eventHandlerToRemove) {
                (0, util_1.remove)(function (eventHandler) { return eventHandler === eventHandlerToRemove; }, _this.eventHandlers);
                _this.element.removeEventListener(eventName, eventHandlerToRemove.handle);
            });
        }
    };
    /**
     * Adds an event handler for a specific event.
     *
     * ```javascript
     * report.on('pageChanged', (event) => {
     *   console.log('PageChanged: ', event.page.name);
     * });
     * ```
     *
     * @template T
     * @param {string} eventName
     * @param {service.IEventHandler<T>} handler
     */
    Embed.prototype.on = function (eventName, handler) {
        if (this.allowedEvents.indexOf(eventName) === -1) {
            throw new Error("eventName must be one of ".concat(this.allowedEvents, ". You passed: ").concat(eventName));
        }
        this.eventHandlers.push({
            test: function (event) { return event.name === eventName; },
            handle: handler
        });
        this.element.addEventListener(eventName, handler);
    };
    /**
     * Reloads embed using existing configuration.
     * E.g. For reports this effectively clears all filters and makes the first page active which simulates resetting a report back to loaded state.
     *
     * ```javascript
     * report.reload();
     * ```
     */
    Embed.prototype.reload = function () {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, this.load()];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * Set accessToken.
     *
     * @returns {Promise<void>}
     */
    Embed.prototype.setAccessToken = function (accessToken) {
        return __awaiter(this, void 0, void 0, function () {
            var embedType, response, response_5;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if (!accessToken) {
                            throw new Error("Access token cannot be empty");
                        }
                        embedType = this.config.type;
                        embedType = (embedType === 'create' || embedType === 'visual' || embedType === 'qna' || embedType === 'quickCreate') ? 'report' : embedType;
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post('/' + embedType + '/token', accessToken, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        this.config.accessToken = accessToken;
                        this.element.setAttribute(Embed.accessTokenAttribute, accessToken);
                        this.service.accessToken = accessToken;
                        return [2 /*return*/, response.body];
                    case 3:
                        response_5 = _a.sent();
                        throw response_5.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Gets an access token from the first available location: config, attribute, global.
     *
     * @private
     * @param {string} globalAccessToken
     * @returns {string}
     * @hidden
     */
    Embed.prototype.getAccessToken = function (globalAccessToken) {
        var accessToken = this.config.accessToken || this.element.getAttribute(Embed.accessTokenAttribute) || globalAccessToken;
        if (!accessToken) {
            throw new Error("No access token was found for element. You must specify an access token directly on the element using attribute '".concat(Embed.accessTokenAttribute, "' or specify a global token at: powerbi.accessToken."));
        }
        return accessToken;
    };
    /**
     * Populate config for create and load
     *
     * @hidden
     * @param {IEmbedConfiguration}
     * @returns {void}
     */
    Embed.prototype.populateConfig = function (config, isBootstrap) {
        var _this = this;
        var _a, _b, _c, _d, _e, _f, _g, _h, _j;
        if (this.bootstrapConfig) {
            this.config = (0, util_1.assign)({}, this.bootstrapConfig, config);
            // reset bootstrapConfig because we do not want to merge it in re-embed scenario.
            this.bootstrapConfig = null;
        }
        else {
            // Copy config - important for multiple iframe scenario.
            // Otherwise, if a user uses the same config twice, same unique Id which will be used in different iframes.
            this.config = (0, util_1.assign)({}, config);
        }
        this.config.embedUrl = this.getEmbedUrl(isBootstrap);
        this.config.groupId = this.getGroupId();
        this.addLocaleToEmbedUrl(config);
        this.config.uniqueId = this.getUniqueId();
        var extensions = (_b = (_a = this.config) === null || _a === void 0 ? void 0 : _a.settings) === null || _b === void 0 ? void 0 : _b.extensions;
        this.commands = (_c = extensions === null || extensions === void 0 ? void 0 : extensions.commands) !== null && _c !== void 0 ? _c : [];
        this.groups = (_d = extensions === null || extensions === void 0 ? void 0 : extensions.groups) !== null && _d !== void 0 ? _d : [];
        this.initialLayoutType = (_g = (_f = (_e = this.config) === null || _e === void 0 ? void 0 : _e.settings) === null || _f === void 0 ? void 0 : _f.layoutType) !== null && _g !== void 0 ? _g : models.LayoutType.Master;
        // Adding commands in extensions array to this.commands
        var extensionsArray = (_j = (_h = this.config) === null || _h === void 0 ? void 0 : _h.settings) === null || _j === void 0 ? void 0 : _j.extensions;
        if (Array.isArray(extensionsArray)) {
            this.commands = [];
            extensionsArray.map(function (extension) { if (extension === null || extension === void 0 ? void 0 : extension.command) {
                _this.commands.push(extension.command);
            } });
        }
        if (isBootstrap) {
            // save current config in bootstrapConfig to be able to merge it on next call to powerbi.embed
            this.bootstrapConfig = this.config;
            this.bootstrapConfig.bootstrapped = true;
        }
        else {
            this.config.accessToken = this.getAccessToken(this.service.accessToken);
        }
        this.eventHooks = this.config.eventHooks;
        this.validateEventHooks(this.eventHooks);
        delete this.config.eventHooks;
        this.configChanged(isBootstrap);
    };
    /**
     * Validate EventHooks
     *
     * @private
     * @param {models.EventHooks} eventHooks
     * @hidden
     */
    Embed.prototype.validateEventHooks = function (eventHooks) {
        if (!eventHooks) {
            return;
        }
        for (var key in eventHooks) {
            if (eventHooks.hasOwnProperty(key) && typeof eventHooks[key] !== 'function') {
                throw new Error(key + " must be a function");
            }
        }
        var applicationContextProvider = eventHooks.applicationContextProvider;
        if (!!applicationContextProvider) {
            if (this.embedtype.toLowerCase() !== "report") {
                throw new Error("applicationContextProvider is only supported in report embed");
            }
            this.config.embedUrl = (0, util_1.addParamToUrl)(this.config.embedUrl, "registerQueryCallback", "true");
        }
        var accessTokenProvider = eventHooks.accessTokenProvider;
        if (!!accessTokenProvider) {
            if ((['create', 'quickcreate', 'report'].indexOf(this.embedtype.toLowerCase()) === -1) || this.config.tokenType !== models.TokenType.Aad) {
                throw new Error("accessTokenProvider is only supported in report SaaS embed");
            }
        }
    };
    /**
     * Adds locale parameters to embedUrl
     *
     * @private
     * @param {IEmbedConfiguration | models.ICommonEmbedConfiguration} config
     * @hidden
     */
    Embed.prototype.addLocaleToEmbedUrl = function (config) {
        if (!config.settings) {
            return;
        }
        var localeSettings = config.settings.localeSettings;
        if (localeSettings && localeSettings.language) {
            this.config.embedUrl = (0, util_1.addParamToUrl)(this.config.embedUrl, 'language', localeSettings.language);
        }
        if (localeSettings && localeSettings.formatLocale) {
            this.config.embedUrl = (0, util_1.addParamToUrl)(this.config.embedUrl, 'formatLocale', localeSettings.formatLocale);
        }
    };
    /**
     * Gets an embed url from the first available location: options, attribute.
     *
     * @private
     * @returns {string}
     * @hidden
     */
    Embed.prototype.getEmbedUrl = function (isBootstrap) {
        var embedUrl = this.config.embedUrl || this.element.getAttribute(Embed.embedUrlAttribute);
        if (isBootstrap && !embedUrl) {
            // Prepare flow, embed url was not provided, use hostname to build embed url.
            embedUrl = this.getDefaultEmbedUrl(this.config.hostname);
        }
        if (typeof embedUrl !== 'string' || embedUrl.length === 0) {
            throw new Error("Embed Url is required, but it was not found. You must provide an embed url either as part of embed configuration or as attribute '".concat(Embed.embedUrlAttribute, "'."));
        }
        return embedUrl;
    };
    /**
     * @hidden
     */
    Embed.prototype.getDefaultEmbedUrl = function (hostname) {
        if (!hostname) {
            hostname = Embed.defaultEmbedHostName;
        }
        var endpoint = this.getDefaultEmbedUrlEndpoint();
        // Trim spaces to fix user mistakes.
        hostname = hostname.toLowerCase().trim();
        if (hostname.indexOf("http://") === 0) {
            throw new Error("HTTP is not allowed. HTTPS is required");
        }
        if (hostname.indexOf("https://") === 0) {
            return "".concat(hostname, "/").concat(endpoint);
        }
        return "https://".concat(hostname, "/").concat(endpoint);
    };
    /**
     * Gets a unique ID from the first available location: options, attribute.
     * If neither is provided generate a unique string.
     *
     * @private
     * @returns {string}
     * @hidden
     */
    Embed.prototype.getUniqueId = function () {
        return this.config.uniqueId || this.element.getAttribute(Embed.nameAttribute) || (0, util_1.createRandomString)();
    };
    /**
     * Gets the group ID from the first available location: options, embeddedUrl.
     *
     * @private
     * @returns {string}
     * @hidden
     */
    Embed.prototype.getGroupId = function () {
        return this.config.groupId || Embed.findGroupIdFromEmbedUrl(this.config.embedUrl);
    };
    /**
     * Requests the browser to render the component's iframe in fullscreen mode.
     */
    Embed.prototype.fullscreen = function () {
        var requestFullScreen = this.iframe.requestFullscreen || this.iframe.msRequestFullscreen || this.iframe.mozRequestFullScreen || this.iframe.webkitRequestFullscreen;
        requestFullScreen.call(this.iframe);
    };
    /**
     * Requests the browser to exit fullscreen mode.
     */
    Embed.prototype.exitFullscreen = function () {
        if (!this.isFullscreen(this.iframe)) {
            return;
        }
        var exitFullscreen = document.exitFullscreen || document.mozCancelFullScreen || document.webkitExitFullscreen || document.msExitFullscreen;
        exitFullscreen.call(document);
    };
    /**
     * Returns true if the iframe is rendered in fullscreen mode,
     * otherwise returns false.
     *
     * @private
     * @param {HTMLIFrameElement} iframe
     * @returns {boolean}
     * @hidden
     */
    Embed.prototype.isFullscreen = function (iframe) {
        var options = ['fullscreenElement', 'webkitFullscreenElement', 'mozFullscreenScreenElement', 'msFullscreenElement'];
        return options.some(function (option) { return document[option] === iframe; });
    };
    /**
     * Sets Iframe for embed
     *
     * @hidden
     */
    Embed.prototype.setIframe = function (isLoad, phasedRender, isBootstrap) {
        var _this = this;
        if (!this.iframe) {
            var iframeContent = document.createElement("iframe");
            var embedUrl = this.config.uniqueId ? (0, util_1.addParamToUrl)(this.config.embedUrl, 'uid', this.config.uniqueId) : this.config.embedUrl;
            iframeContent.style.width = '100%';
            iframeContent.style.height = '100%';
            iframeContent.setAttribute("src", embedUrl);
            iframeContent.setAttribute("scrolling", "no");
            iframeContent.setAttribute("allowfullscreen", "true");
            var node = this.element;
            while (node.firstChild) {
                node.removeChild(node.firstChild);
            }
            node.appendChild(iframeContent);
            this.iframe = node.firstChild;
        }
        if (isLoad) {
            if (!isBootstrap) {
                // Validate config if it's not a bootstrap case.
                var errors = this.validate(this.config);
                if (errors) {
                    throw errors;
                }
            }
            this.iframe.addEventListener('load', function () {
                _this.iframeLoaded = true;
                _this.load(phasedRender);
            }, false);
            if (this.service.getNumberOfComponents() <= Embed.maxFrontLoadTimes) {
                this.frontLoadHandler = function () {
                    _this.frontLoadSendConfig(_this.config);
                };
                // 'ready' event is fired by the embedded element (not by the iframe)
                this.element.addEventListener('ready', this.frontLoadHandler, false);
            }
        }
        else {
            this.iframe.addEventListener('load', function () { return _this.create(); }, false);
        }
    };
    /**
     * Set the component title for accessibility. In case of iframes, this method will change the iframe title.
     */
    Embed.prototype.setComponentTitle = function (title) {
        if (!this.iframe) {
            return;
        }
        if (title == null) {
            this.iframe.removeAttribute("title");
        }
        else {
            this.iframe.setAttribute("title", title);
        }
    };
    /**
     * Sets element's tabindex attribute
     */
    Embed.prototype.setComponentTabIndex = function (tabIndex) {
        if (!this.element) {
            return;
        }
        this.element.setAttribute("tabindex", (tabIndex == null) ? "0" : tabIndex.toString());
    };
    /**
     * Removes element's tabindex attribute
     */
    Embed.prototype.removeComponentTabIndex = function (_tabIndex) {
        if (!this.element) {
            return;
        }
        this.element.removeAttribute("tabindex");
    };
    /**
     * Adds the ability to get groupId from url.
     * By extracting the ID we can ensure that the ID is always explicitly provided as part of the load configuration.
     *
     * @hidden
     * @static
     * @param {string} url
     * @returns {string}
     */
    Embed.findGroupIdFromEmbedUrl = function (url) {
        var groupIdRegEx = /groupId="?([^&]+)"?/;
        var groupIdMatch = url.match(groupIdRegEx);
        var groupId;
        if (groupIdMatch) {
            groupId = groupIdMatch[1];
        }
        return groupId;
    };
    /**
     * Sends the config for front load calls, after 'ready' message is received from the iframe
     *
     * @hidden
     */
    Embed.prototype.frontLoadSendConfig = function (config) {
        return __awaiter(this, void 0, void 0, function () {
            var errors, response, response_6;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if (!config.accessToken) {
                            return [2 /*return*/];
                        }
                        errors = this.validate(config);
                        if (errors) {
                            throw errors;
                        }
                        // contentWindow must be initialized
                        if (this.iframe.contentWindow == null) {
                            return [2 /*return*/];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post("/frontload/config", config, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_6 = _a.sent();
                        throw response_6.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /** @hidden */
    Embed.allowedEvents = ["loaded", "saved", "rendered", "saveAsTriggered", "error", "dataSelected", "buttonClicked", "info"];
    /** @hidden */
    Embed.accessTokenAttribute = 'powerbi-access-token';
    /** @hidden */
    Embed.embedUrlAttribute = 'powerbi-embed-url';
    /** @hidden */
    Embed.nameAttribute = 'powerbi-name';
    /** @hidden */
    Embed.typeAttribute = 'powerbi-type';
    /** @hidden */
    Embed.defaultEmbedHostName = "https://app.powerbi.com";
    /** @hidden */
    Embed.maxFrontLoadTimes = 2;
    return Embed;
}());
exports.Embed = Embed;


/***/ }),

/***/ "./src/errors.ts":
/*!***********************!*\
  !*** ./src/errors.ts ***!
  \***********************/
/***/ ((__unused_webpack_module, exports) => {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.EmbedUrlNotSupported = exports.APINotSupportedForRDLError = void 0;
exports.APINotSupportedForRDLError = "This API is currently not supported for RDL reports";
exports.EmbedUrlNotSupported = "Embed URL is invalid for this scenario. Please use Power BI REST APIs to get the valid URL";


/***/ }),

/***/ "./src/factories.ts":
/*!**************************!*\
  !*** ./src/factories.ts ***!
  \**************************/
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.routerFactory = exports.wpmpFactory = exports.hpmFactory = void 0;
/**
 * TODO: Need to find better place for these factory functions or refactor how we handle dependency injection
 */
var window_post_message_proxy_1 = __webpack_require__(/*! window-post-message-proxy */ "./node_modules/window-post-message-proxy/dist/windowPostMessageProxy.js");
var http_post_message_1 = __webpack_require__(/*! http-post-message */ "./node_modules/http-post-message/dist/httpPostMessage.js");
var powerbi_router_1 = __webpack_require__(/*! powerbi-router */ "./node_modules/powerbi-router/dist/router.js");
var config_1 = __webpack_require__(/*! ./config */ "./src/config.ts");
var hpmFactory = function (wpmp, defaultTargetWindow, sdkVersion, sdkType, sdkWrapperVersion) {
    if (sdkVersion === void 0) { sdkVersion = config_1.default.version; }
    if (sdkType === void 0) { sdkType = config_1.default.type; }
    return new http_post_message_1.HttpPostMessage(wpmp, {
        'x-sdk-type': sdkType,
        'x-sdk-version': sdkVersion,
        'x-sdk-wrapper-version': sdkWrapperVersion,
    }, defaultTargetWindow);
};
exports.hpmFactory = hpmFactory;
var wpmpFactory = function (name, logMessages, eventSourceOverrideWindow) {
    return new window_post_message_proxy_1.WindowPostMessageProxy({
        processTrackingProperties: {
            addTrackingProperties: http_post_message_1.HttpPostMessage.addTrackingProperties,
            getTrackingProperties: http_post_message_1.HttpPostMessage.getTrackingProperties,
        },
        isErrorMessage: http_post_message_1.HttpPostMessage.isErrorMessage,
        suppressWarnings: true,
        name: name,
        logMessages: logMessages,
        eventSourceOverrideWindow: eventSourceOverrideWindow
    });
};
exports.wpmpFactory = wpmpFactory;
var routerFactory = function (wpmp) {
    return new powerbi_router_1.Router(wpmp);
};
exports.routerFactory = routerFactory;


/***/ }),

/***/ "./src/page.ts":
/*!*********************!*\
  !*** ./src/page.ts ***!
  \*********************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.Page = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var visualDescriptor_1 = __webpack_require__(/*! ./visualDescriptor */ "./src/visualDescriptor.ts");
var util_1 = __webpack_require__(/*! ./util */ "./src/util.ts");
var errors_1 = __webpack_require__(/*! ./errors */ "./src/errors.ts");
/**
 * A Power BI report page
 *
 * @export
 * @class Page
 * @implements {IPageNode}
 * @implements {IFilterable}
 */
var Page = /** @class */ (function () {
    /**
     * Creates an instance of a Power BI report page.
     *
     * @param {IReportNode} report
     * @param {string} name
     * @param {string} [displayName]
     * @param {boolean} [isActivePage]
     * @param {SectionVisibility} [visibility]
     * @hidden
     */
    function Page(report, name, displayName, isActivePage, visibility, defaultSize, defaultDisplayOption, mobileSize, background, wallpaper) {
        this.report = report;
        this.name = name;
        this.displayName = displayName;
        this.isActive = isActivePage;
        this.visibility = visibility;
        this.defaultSize = defaultSize;
        this.mobileSize = mobileSize;
        this.defaultDisplayOption = defaultDisplayOption;
        this.background = background;
        this.wallpaper = wallpaper;
    }
    /**
     * Gets all page level filters within the report.
     *
     * ```javascript
     * page.getFilters()
     *  .then(filters => { ... });
     * ```
     *
     * @returns {(Promise<IFilter[]>)}
     */
    Page.prototype.getFilters = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_1;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.report.service.hpm.get("/report/pages/".concat(this.name, "/filters"), { uid: this.report.config.uniqueId }, this.report.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_1 = _a.sent();
                        throw response_1.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Update the filters for the current page according to the operation: Add, replace all, replace by target or remove.
     *
     * ```javascript
     * page.updateFilters(FiltersOperations.Add, filters)
     *   .catch(errors => { ... });
     * ```
     *
     * @param {(IFilter[])} filters
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Page.prototype.updateFilters = function (operation, filters) {
        return __awaiter(this, void 0, void 0, function () {
            var updateFiltersRequest, response_2;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        updateFiltersRequest = {
                            filtersOperation: operation,
                            filters: filters
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.report.service.hpm.post("/report/pages/".concat(this.name, "/filters"), updateFiltersRequest, { uid: this.report.config.uniqueId }, this.report.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_2 = _a.sent();
                        throw response_2.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Removes all filters from this page of the report.
     *
     * ```javascript
     * page.removeFilters();
     * ```
     *
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Page.prototype.removeFilters = function () {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, this.updateFilters(powerbi_models_1.FiltersOperations.RemoveAll)];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * Sets all filters on the current page.
     *
     * ```javascript
     * page.setFilters(filters)
     *   .catch(errors => { ... });
     * ```
     *
     * @param {(IFilter[])} filters
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Page.prototype.setFilters = function (filters) {
        return __awaiter(this, void 0, void 0, function () {
            var response_3;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.report.service.hpm.put("/report/pages/".concat(this.name, "/filters"), filters, { uid: this.report.config.uniqueId }, this.report.iframe.contentWindow)];
                    case 1: return [2 /*return*/, _a.sent()];
                    case 2:
                        response_3 = _a.sent();
                        throw response_3.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Delete the page from the report
     *
     * ```javascript
     * // Delete the page from the report
     * page.delete();
     * ```
     *
     * @returns {Promise<void>}
     */
    Page.prototype.delete = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_4;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.report.service.hpm.delete("/report/pages/".concat(this.name), {}, { uid: this.report.config.uniqueId }, this.report.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_4 = _a.sent();
                        throw response_4.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Makes the current page the active page of the report.
     *
     * ```javascript
     * page.setActive();
     * ```
     *
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Page.prototype.setActive = function () {
        return __awaiter(this, void 0, void 0, function () {
            var page, response_5;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        page = {
                            name: this.name,
                            displayName: null,
                            isActive: true
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.report.service.hpm.put('/report/pages/active', page, { uid: this.report.config.uniqueId }, this.report.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_5 = _a.sent();
                        throw response_5.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Set displayName to the current page.
     *
     * ```javascript
     * page.setName(displayName);
     * ```
     *
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Page.prototype.setDisplayName = function (displayName) {
        return __awaiter(this, void 0, void 0, function () {
            var page, response_6;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        page = {
                            name: this.name,
                            displayName: displayName,
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.report.service.hpm.put("/report/pages/".concat(this.name, "/name"), page, { uid: this.report.config.uniqueId }, this.report.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_6 = _a.sent();
                        throw response_6.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Gets all the visuals on the page.
     *
     * ```javascript
     * page.getVisuals()
     *   .then(visuals => { ... });
     * ```
     *
     * @returns {Promise<VisualDescriptor[]>}
     */
    Page.prototype.getVisuals = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_7;
            var _this = this;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.report.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.report.service.hpm.get("/report/pages/".concat(this.name, "/visuals"), { uid: this.report.config.uniqueId }, this.report.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body
                                .map(function (visual) { return new visualDescriptor_1.VisualDescriptor(_this, visual.name, visual.title, visual.type, visual.layout); })];
                    case 3:
                        response_7 = _a.sent();
                        throw response_7.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Gets a visual by name on the page.
     *
     * ```javascript
     * page.getVisualByName(visualName: string)
     *  .then(visual => {
     *      ...
     *  });
     * ```
     *
     * @param {string} visualName
     * @returns {Promise<VisualDescriptor>}
     */
    Page.prototype.getVisualByName = function (visualName) {
        return __awaiter(this, void 0, void 0, function () {
            var response, visual, response_8;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.report.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.report.service.hpm.get("/report/pages/".concat(this.name, "/visuals"), { uid: this.report.config.uniqueId }, this.report.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        visual = response.body.find(function (v) { return v.name === visualName; });
                        if (!visual) {
                            return [2 /*return*/, Promise.reject(powerbi_models_1.CommonErrorCodes.NotFound)];
                        }
                        return [2 /*return*/, new visualDescriptor_1.VisualDescriptor(this, visual.name, visual.title, visual.type, visual.layout)];
                    case 3:
                        response_8 = _a.sent();
                        throw response_8.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Updates the display state of a visual in a page.
     *
     * ```javascript
     * page.setVisualDisplayState(visualName, displayState)
     *   .catch(error => { ... });
     * ```
     *
     * @param {string} visualName
     * @param {VisualContainerDisplayMode} displayState
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Page.prototype.setVisualDisplayState = function (visualName, displayState) {
        return __awaiter(this, void 0, void 0, function () {
            var pageName, report;
            return __generator(this, function (_a) {
                pageName = this.name;
                report = this.report;
                return [2 /*return*/, report.setVisualDisplayState(pageName, visualName, displayState)];
            });
        });
    };
    /**
     * Updates the position of a visual in a page.
     *
     * ```javascript
     * page.moveVisual(visualName, x, y, z)
     *   .catch(error => { ... });
     * ```
     *
     * @param {string} visualName
     * @param {number} x
     * @param {number} y
     * @param {number} z
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Page.prototype.moveVisual = function (visualName, x, y, z) {
        return __awaiter(this, void 0, void 0, function () {
            var pageName, report;
            return __generator(this, function (_a) {
                pageName = this.name;
                report = this.report;
                return [2 /*return*/, report.moveVisual(pageName, visualName, x, y, z)];
            });
        });
    };
    /**
     * Resize a visual in a page.
     *
     * ```javascript
     * page.resizeVisual(visualName, width, height)
     *   .catch(error => { ... });
     * ```
     *
     * @param {string} visualName
     * @param {number} width
     * @param {number} height
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Page.prototype.resizeVisual = function (visualName, width, height) {
        return __awaiter(this, void 0, void 0, function () {
            var pageName, report;
            return __generator(this, function (_a) {
                pageName = this.name;
                report = this.report;
                return [2 /*return*/, report.resizeVisual(pageName, visualName, width, height)];
            });
        });
    };
    /**
     * Updates the size of active page.
     *
     * ```javascript
     * page.resizePage(pageSizeType, width, height)
     *   .catch(error => { ... });
     * ```
     *
     * @param {PageSizeType} pageSizeType
     * @param {number} width
     * @param {number} height
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Page.prototype.resizePage = function (pageSizeType, width, height) {
        return __awaiter(this, void 0, void 0, function () {
            var report;
            return __generator(this, function (_a) {
                if (!this.isActive) {
                    return [2 /*return*/, Promise.reject('Cannot resize the page. Only the active page can be resized')];
                }
                report = this.report;
                return [2 /*return*/, report.resizeActivePage(pageSizeType, width, height)];
            });
        });
    };
    /**
     * Gets the list of slicer visuals on the page.
     *
     * ```javascript
     * page.getSlicers()
     *  .then(slicers => {
     *      ...
     *  });
     * ```
     *
     * @returns {Promise<IVisual[]>}
     */
    Page.prototype.getSlicers = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_9;
            var _this = this;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.report.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.report.service.hpm.get("/report/pages/".concat(this.name, "/visuals"), { uid: this.report.config.uniqueId }, this.report.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body
                                .filter(function (visual) { return visual.type === 'slicer'; })
                                .map(function (visual) { return new visualDescriptor_1.VisualDescriptor(_this, visual.name, visual.title, visual.type, visual.layout); })];
                    case 3:
                        response_9 = _a.sent();
                        throw response_9.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Checks if page has layout.
     *
     * ```javascript
     * page.hasLayout(layoutType)
     *  .then(hasLayout: boolean => { ... });
     * ```
     *
     * @returns {(Promise<boolean>)}
     */
    Page.prototype.hasLayout = function (layoutType) {
        return __awaiter(this, void 0, void 0, function () {
            var layoutTypeEnum, response, response_10;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.report.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        layoutTypeEnum = powerbi_models_1.LayoutType[layoutType];
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.report.service.hpm.get("/report/pages/".concat(this.name, "/layoutTypes/").concat(layoutTypeEnum), { uid: this.report.config.uniqueId }, this.report.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_10 = _a.sent();
                        throw response_10.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    return Page;
}());
exports.Page = Page;


/***/ }),

/***/ "./src/qna.ts":
/*!********************!*\
  !*** ./src/qna.ts ***!
  \********************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.Qna = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var embed_1 = __webpack_require__(/*! ./embed */ "./src/embed.ts");
/**
 * The Power BI Q&A embed component
 *
 * @export
 * @class Qna
 * @extends {Embed}
 */
var Qna = /** @class */ (function (_super) {
    __extends(Qna, _super);
    /**
     * @hidden
     */
    function Qna(service, element, config, phasedRender, isBootstrap) {
        var _this = _super.call(this, service, element, config, /* iframe */ undefined, phasedRender, isBootstrap) || this;
        _this.loadPath = "/qna/load";
        _this.phasedLoadPath = "/qna/prepare";
        Array.prototype.push.apply(_this.allowedEvents, Qna.allowedEvents);
        return _this;
    }
    /**
     * The ID of the Q&A embed component
     *
     * @returns {string}
     */
    Qna.prototype.getId = function () {
        return null;
    };
    /**
     * Change the question of the Q&A embed component
     *
     * @param {string} question - question which will render Q&A data
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Qna.prototype.setQuestion = function (question) {
        return __awaiter(this, void 0, void 0, function () {
            var qnaData, response_1;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        qnaData = {
                            question: question
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post('/qna/interpret', qnaData, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_1 = _a.sent();
                        throw response_1.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Handle config changes.
     *
     * @returns {void}
     */
    Qna.prototype.configChanged = function (_isBootstrap) {
        // Nothing to do in Q&A embed.
    };
    /**
     * @hidden
     * @returns {string}
     */
    Qna.prototype.getDefaultEmbedUrlEndpoint = function () {
        return "qnaEmbed";
    };
    /**
     * Validate load configuration.
     */
    Qna.prototype.validate = function (config) {
        return (0, powerbi_models_1.validateLoadQnaConfiguration)(config);
    };
    /** @hidden */
    Qna.type = "Qna";
    /** @hidden */
    Qna.allowedEvents = ["loaded", "visualRendered"];
    return Qna;
}(embed_1.Embed));
exports.Qna = Qna;


/***/ }),

/***/ "./src/quickCreate.ts":
/*!****************************!*\
  !*** ./src/quickCreate.ts ***!
  \****************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.QuickCreate = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var embed_1 = __webpack_require__(/*! ./embed */ "./src/embed.ts");
/**
 * A Power BI Quick Create component
 *
 * @export
 * @class QuickCreate
 * @extends {Embed}
 */
var QuickCreate = /** @class */ (function (_super) {
    __extends(QuickCreate, _super);
    /*
     * @hidden
     */
    function QuickCreate(service, element, config, phasedRender, isBootstrap) {
        var _this = _super.call(this, service, element, config, /* iframe */ undefined, phasedRender, isBootstrap) || this;
        service.router.post("/reports/".concat(_this.config.uniqueId, "/eventHooks/:eventName"), function (req, _res) { return __awaiter(_this, void 0, void 0, function () {
            var _a;
            var _b;
            return __generator(this, function (_c) {
                switch (_c.label) {
                    case 0:
                        _a = req.params.eventName;
                        switch (_a) {
                            case "newAccessToken": return [3 /*break*/, 1];
                        }
                        return [3 /*break*/, 3];
                    case 1:
                        req.body = req.body || {};
                        req.body.report = this;
                        return [4 /*yield*/, service.invokeSDKHook((_b = this.eventHooks) === null || _b === void 0 ? void 0 : _b.accessTokenProvider, req, _res)];
                    case 2:
                        _c.sent();
                        return [3 /*break*/, 4];
                    case 3: return [3 /*break*/, 4];
                    case 4: return [2 /*return*/];
                }
            });
        }); });
        return _this;
    }
    /**
     * Override the getId abstract function
     * QuickCreate does not need any ID
     *
     * @returns {string}
     */
    QuickCreate.prototype.getId = function () {
        return null;
    };
    /**
     * Validate create report configuration.
     */
    QuickCreate.prototype.validate = function (config) {
        return (0, powerbi_models_1.validateQuickCreate)(config);
    };
    /**
     * Handle config changes.
     *
     * @hidden
     * @returns {void}
     */
    QuickCreate.prototype.configChanged = function (isBootstrap) {
        if (isBootstrap) {
            return;
        }
        this.createConfig = this.config;
    };
    /**
     * @hidden
     * @returns {string}
     */
    QuickCreate.prototype.getDefaultEmbedUrlEndpoint = function () {
        return "quickCreate";
    };
    /**
     * Sends quickCreate configuration data.
     *
     * ```javascript
     * quickCreate({
     *   accessToken: 'eyJ0eXA ... TaE2rTSbmg',
     *   datasetCreateConfig: {}})
     * ```
     *
     * @hidden
     * @param {IQuickCreateConfiguration} createConfig
     * @returns {Promise<void>}
     */
    QuickCreate.prototype.create = function () {
        var _a;
        return __awaiter(this, void 0, void 0, function () {
            var errors, headers, response, response_1;
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        errors = (0, powerbi_models_1.validateQuickCreate)(this.createConfig);
                        if (errors) {
                            throw errors;
                        }
                        _b.label = 1;
                    case 1:
                        _b.trys.push([1, 3, , 4]);
                        headers = {
                            uid: this.config.uniqueId,
                            sdkSessionId: this.service.getSdkSessionId()
                        };
                        if (!!((_a = this.eventHooks) === null || _a === void 0 ? void 0 : _a.accessTokenProvider)) {
                            headers.tokenProviderSupplied = true;
                        }
                        return [4 /*yield*/, this.service.hpm.post("/quickcreate", this.createConfig, headers, this.iframe.contentWindow)];
                    case 2:
                        response = _b.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_1 = _b.sent();
                        throw response_1.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    return QuickCreate;
}(embed_1.Embed));
exports.QuickCreate = QuickCreate;


/***/ }),

/***/ "./src/report.ts":
/*!***********************!*\
  !*** ./src/report.ts ***!
  \***********************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.Report = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var embed_1 = __webpack_require__(/*! ./embed */ "./src/embed.ts");
var util_1 = __webpack_require__(/*! ./util */ "./src/util.ts");
var errors_1 = __webpack_require__(/*! ./errors */ "./src/errors.ts");
var page_1 = __webpack_require__(/*! ./page */ "./src/page.ts");
var bookmarksManager_1 = __webpack_require__(/*! ./bookmarksManager */ "./src/bookmarksManager.ts");
/**
 * The Power BI Report embed component
 *
 * @export
 * @class Report
 * @extends {Embed}
 * @implements {IReportNode}
 * @implements {IFilterable}
 */
var Report = /** @class */ (function (_super) {
    __extends(Report, _super);
    /**
     * Creates an instance of a Power BI Report.
     *
     * @param {Service} service
     * @param {HTMLElement} element
     * @param {IEmbedConfiguration} config
     * @hidden
     */
    function Report(service, element, baseConfig, phasedRender, isBootstrap, iframe) {
        var _this = this;
        var config = baseConfig;
        _this = _super.call(this, service, element, config, iframe, phasedRender, isBootstrap) || this;
        _this.loadPath = "/report/load";
        _this.phasedLoadPath = "/report/prepare";
        Array.prototype.push.apply(_this.allowedEvents, Report.allowedEvents);
        _this.bookmarksManager = new bookmarksManager_1.BookmarksManager(service, config, _this.iframe);
        service.router.post("/reports/".concat(_this.config.uniqueId, "/eventHooks/:eventName"), function (req, _res) { return __awaiter(_this, void 0, void 0, function () {
            var _a;
            var _b, _c;
            return __generator(this, function (_d) {
                switch (_d.label) {
                    case 0:
                        _a = req.params.eventName;
                        switch (_a) {
                            case "preQuery": return [3 /*break*/, 1];
                            case "newAccessToken": return [3 /*break*/, 3];
                        }
                        return [3 /*break*/, 5];
                    case 1:
                        req.body = req.body || {};
                        req.body.report = this;
                        return [4 /*yield*/, service.invokeSDKHook((_b = this.eventHooks) === null || _b === void 0 ? void 0 : _b.applicationContextProvider, req, _res)];
                    case 2:
                        _d.sent();
                        return [3 /*break*/, 6];
                    case 3:
                        req.body = req.body || {};
                        req.body.report = this;
                        return [4 /*yield*/, service.invokeSDKHook((_c = this.eventHooks) === null || _c === void 0 ? void 0 : _c.accessTokenProvider, req, _res)];
                    case 4:
                        _d.sent();
                        return [3 /*break*/, 6];
                    case 5: return [3 /*break*/, 6];
                    case 6: return [2 /*return*/];
                }
            });
        }); });
        return _this;
    }
    /**
     * Adds backwards compatibility for the previous load configuration, which used the reportId query parameter to specify the report ID
     * (e.g. http://embedded.powerbi.com/appTokenReportEmbed?reportId=854846ed-2106-4dc2-bc58-eb77533bf2f1).
     *
     * By extracting the ID we can ensure that the ID is always explicitly provided as part of the load configuration.
     *
     * @hidden
     * @static
     * @param {string} url
     * @returns {string}
     */
    Report.findIdFromEmbedUrl = function (url) {
        var reportIdRegEx = /reportId="?([^&]+)"?/;
        var reportIdMatch = url.match(reportIdRegEx);
        var reportId;
        if (reportIdMatch) {
            reportId = reportIdMatch[1];
        }
        return reportId;
    };
    /**
     * Render a preloaded report, using phased embedding API
     *
     * ```javascript
     * // Load report
     * var report = powerbi.load(element, config);
     *
     * ...
     *
     * // Render report
     * report.render()
     * ```
     *
     * @returns {Promise<void>}
     */
    Report.prototype.render = function (config) {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_1;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.service.hpm.post("/report/render", config, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_1 = _a.sent();
                        throw response_1.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Add an empty page to the report
     *
     * ```javascript
     * // Add a page to the report with "Sales" as the page display name
     * report.addPage("Sales");
     * ```
     *
     * @returns {Promise<Page>}
     */
    Report.prototype.addPage = function (displayName) {
        return __awaiter(this, void 0, void 0, function () {
            var request, response, page, response_2;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        request = {
                            displayName: displayName
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post("/report/addPage", request, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        page = response.body;
                        return [2 /*return*/, new page_1.Page(this, page.name, page.displayName, page.isActive, page.visibility, page.defaultSize, page.defaultDisplayOption)];
                    case 3:
                        response_2 = _a.sent();
                        throw response_2.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Delete a page from a report
     *
     * ```javascript
     * // Delete a page from a report by pageName (PageName is different than the display name and can be acquired from the getPages API)
     * report.deletePage("ReportSection145");
     * ```
     *
     * @returns {Promise<void>}
     */
    Report.prototype.deletePage = function (pageName) {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_3;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.service.hpm.delete("/report/pages/".concat(pageName), {}, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_3 = _a.sent();
                        throw response_3.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Rename a page from a report
     *
     * ```javascript
     * // Rename a page from a report by changing displayName (pageName is different from the display name and can be acquired from the getPages API)
     * report.renamePage("ReportSection145", "Sales");
     * ```
     *
     * @returns {Promise<void>}
     */
    Report.prototype.renamePage = function (pageName, displayName) {
        return __awaiter(this, void 0, void 0, function () {
            var page, response, response_4;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        page = {
                            name: pageName,
                            displayName: displayName,
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.put("/report/pages/".concat(pageName, "/name"), page, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_4 = _a.sent();
                        throw response_4.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Gets filters that are applied at the report level.
     *
     * ```javascript
     * // Get filters applied at report level
     * report.getFilters()
     *   .then(filters => {
     *     ...
     *   });
     * ```
     *
     * @returns {Promise<IFilter[]>}
     */
    Report.prototype.getFilters = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_5;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.get("/report/filters", { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_5 = _a.sent();
                        throw response_5.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Update the filters at the report level according to the operation: Add, replace all, replace by target or remove.
     *
     * ```javascript
     * report.updateFilters(FiltersOperations.Add, filters)
     *   .catch(errors => { ... });
     * ```
     *
     * @param {(IFilter[])} filters
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.updateFilters = function (operation, filters) {
        return __awaiter(this, void 0, void 0, function () {
            var updateFiltersRequest, response_6;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        updateFiltersRequest = {
                            filtersOperation: operation,
                            filters: filters
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post("/report/filters", updateFiltersRequest, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_6 = _a.sent();
                        throw response_6.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Removes all filters at the report level.
     *
     * ```javascript
     * report.removeFilters();
     * ```
     *
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.removeFilters = function () {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                    return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                }
                return [2 /*return*/, this.updateFilters(powerbi_models_1.FiltersOperations.RemoveAll)];
            });
        });
    };
    /**
     * Sets filters at the report level.
     *
     * ```javascript
     * const filters: [
     *    ...
     * ];
     *
     * report.setFilters(filters)
     *  .catch(errors => {
     *    ...
     *  });
     * ```
     *
     * @param {(IFilter[])} filters
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.setFilters = function (filters) {
        return __awaiter(this, void 0, void 0, function () {
            var response_7;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.put("/report/filters", filters, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_7 = _a.sent();
                        throw response_7.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Gets the report ID from the first available location: options, attribute, embed url.
     *
     * @returns {string}
     */
    Report.prototype.getId = function () {
        var config = this.config;
        var reportId = config.id || this.element.getAttribute(Report.reportIdAttribute) || Report.findIdFromEmbedUrl(config.embedUrl);
        if (typeof reportId !== 'string' || reportId.length === 0) {
            throw new Error("Report id is required, but it was not found. You must provide an id either as part of embed configuration or as attribute '".concat(Report.reportIdAttribute, "'."));
        }
        return reportId;
    };
    /**
     * Gets the list of pages within the report.
     *
     * ```javascript
     * report.getPages()
     *  .then(pages => {
     *      ...
     *  });
     * ```
     *
     * @returns {Promise<Page[]>}
     */
    Report.prototype.getPages = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_8;
            var _this = this;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.get('/report/pages', { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body
                                .map(function (page) { return new page_1.Page(_this, page.name, page.displayName, page.isActive, page.visibility, page.defaultSize, page.defaultDisplayOption, page.mobileSize, page.background, page.wallpaper); })];
                    case 3:
                        response_8 = _a.sent();
                        throw response_8.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Gets a report page by its name.
     *
     * ```javascript
     * report.getPageByName(pageName)
     *  .then(page => {
     *      ...
     *  });
     * ```
     *
     * @param {string} pageName
     * @returns {Promise<Page>}
     */
    Report.prototype.getPageByName = function (pageName) {
        return __awaiter(this, void 0, void 0, function () {
            var response, page, response_9;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.get("/report/pages", { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        page = response.body.find(function (p) { return p.name === pageName; });
                        if (!page) {
                            return [2 /*return*/, Promise.reject(powerbi_models_1.CommonErrorCodes.NotFound)];
                        }
                        return [2 /*return*/, new page_1.Page(this, page.name, page.displayName, page.isActive, page.visibility, page.defaultSize, page.defaultDisplayOption, page.mobileSize, page.background, page.wallpaper)];
                    case 3:
                        response_9 = _a.sent();
                        throw response_9.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Gets the active report page.
     *
     * ```javascript
     * report.getActivePage()
     *  .then(activePage => {
     *      ...
     *  });
     * ```
     *
     * @returns {Promise<Page>}
     */
    Report.prototype.getActivePage = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, activePage, response_10;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.get('/report/pages', { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        activePage = response.body.find(function (page) { return page.isActive; });
                        return [2 /*return*/, new page_1.Page(this, activePage.name, activePage.displayName, activePage.isActive, activePage.visibility, activePage.defaultSize, activePage.defaultDisplayOption, activePage.mobileSize, activePage.background, activePage.wallpaper)];
                    case 3:
                        response_10 = _a.sent();
                        throw response_10.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Creates an instance of a Page.
     *
     * Normally you would get Page objects by calling `report.getPages()`, but in the case
     * that the page name is known and you want to perform an action on a page without having to retrieve it
     * you can create it directly.
     *
     * Note: Because you are creating the page manually there is no guarantee that the page actually exists in the report, and subsequent requests could fail.
     *
     * @param {string} name
     * @param {string} [displayName]
     * @param {boolean} [isActive]
     * @returns {Page}
     * @hidden
     */
    Report.prototype.page = function (name, displayName, isActive, visibility) {
        return new page_1.Page(this, name, displayName, isActive, visibility);
    };
    /**
     * Prints the active page of the report by invoking `window.print()` on the embed iframe component.
     */
    Report.prototype.print = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_11;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post('/report/print', null, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_11 = _a.sent();
                        throw response_11.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Sets the active page of the report.
     *
     * ```javascript
     * report.setPage("page2")
     *  .catch(error => { ... });
     * ```
     *
     * @param {string} pageName
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.setPage = function (pageName) {
        return __awaiter(this, void 0, void 0, function () {
            var page, response_12;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        page = {
                            name: pageName,
                            displayName: null,
                            isActive: true
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.put('/report/pages/active', page, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_12 = _a.sent();
                        throw response_12.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Updates visibility settings for the filter pane and the page navigation pane.
     *
     * ```javascript
     * const newSettings = {
     *   panes: {
     *     filters: {
     *       visible: false
     *     }
     *   }
     * };
     *
     * report.updateSettings(newSettings)
     *   .catch(error => { ... });
     * ```
     *
     * @param {ISettings} settings
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.updateSettings = function (settings) {
        var _a, _b;
        return __awaiter(this, void 0, void 0, function () {
            var response, extension, extensionsArray, response_13;
            var _this = this;
            return __generator(this, function (_c) {
                switch (_c.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl) && settings.customLayout != null) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _c.label = 1;
                    case 1:
                        _c.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.patch('/report/settings', settings, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _c.sent();
                        extension = settings === null || settings === void 0 ? void 0 : settings.extensions;
                        this.commands = (_a = extension === null || extension === void 0 ? void 0 : extension.commands) !== null && _a !== void 0 ? _a : this.commands;
                        this.groups = (_b = extension === null || extension === void 0 ? void 0 : extension.groups) !== null && _b !== void 0 ? _b : this.groups;
                        extensionsArray = settings === null || settings === void 0 ? void 0 : settings.extensions;
                        if (Array.isArray(extensionsArray)) {
                            this.commands = [];
                            extensionsArray.map(function (extensionElement) { if (extensionElement === null || extensionElement === void 0 ? void 0 : extensionElement.command) {
                                _this.commands.push(extensionElement.command);
                            } });
                        }
                        return [2 /*return*/, response];
                    case 3:
                        response_13 = _c.sent();
                        throw response_13.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Validate load configuration.
     *
     * @hidden
     */
    Report.prototype.validate = function (config) {
        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
            return (0, powerbi_models_1.validatePaginatedReportLoad)(config);
        }
        return (0, powerbi_models_1.validateReportLoad)(config);
    };
    /**
     * Handle config changes.
     *
     * @returns {void}
     */
    Report.prototype.configChanged = function (isBootstrap) {
        var config = this.config;
        if (this.isMobileSettings(config.settings)) {
            config.embedUrl = (0, util_1.addParamToUrl)(config.embedUrl, "isMobile", "true");
        }
        // Calculate settings from HTML element attributes if available.
        var filterPaneEnabledAttribute = this.element.getAttribute(Report.filterPaneEnabledAttribute);
        var navContentPaneEnabledAttribute = this.element.getAttribute(Report.navContentPaneEnabledAttribute);
        var elementAttrSettings = {
            filterPaneEnabled: (filterPaneEnabledAttribute == null) ? undefined : (filterPaneEnabledAttribute !== "false"),
            navContentPaneEnabled: (navContentPaneEnabledAttribute == null) ? undefined : (navContentPaneEnabledAttribute !== "false")
        };
        // Set the settings back into the config.
        this.config.settings = (0, util_1.assign)({}, elementAttrSettings, config.settings);
        if (isBootstrap) {
            return;
        }
        config.id = this.getId();
    };
    /**
     * @hidden
     * @returns {string}
     */
    Report.prototype.getDefaultEmbedUrlEndpoint = function () {
        return "reportEmbed";
    };
    /**
     * Switch Report view mode.
     *
     * @returns {Promise<void>}
     */
    Report.prototype.switchMode = function (viewMode) {
        return __awaiter(this, void 0, void 0, function () {
            var newMode, url, response, response_14;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if (typeof viewMode === "string") {
                            newMode = viewMode;
                        }
                        else {
                            newMode = this.viewModeToString(viewMode);
                        }
                        url = '/report/switchMode/' + newMode;
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post(url, null, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_14 = _a.sent();
                        throw response_14.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Refreshes data sources for the report.
     *
     * ```javascript
     * report.refresh();
     * ```
     */
    Report.prototype.refresh = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_15;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.service.hpm.post('/report/refresh', null, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_15 = _a.sent();
                        throw response_15.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * checks if the report is saved.
     *
     * ```javascript
     * report.isSaved()
     * ```
     *
     * @returns {Promise<boolean>}
     */
    Report.prototype.isSaved = function () {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        return [4 /*yield*/, (0, util_1.isSavedInternal)(this.service.hpm, this.config.uniqueId, this.iframe.contentWindow)];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * Apply a theme to the report
     *
     * ```javascript
     * report.applyTheme(theme);
     * ```
     */
    Report.prototype.applyTheme = function (theme) {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        return [4 /*yield*/, this.applyThemeInternal(theme)];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * Reset and apply the default theme of the report
     *
     * ```javascript
     * report.resetTheme();
     * ```
     */
    Report.prototype.resetTheme = function () {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        return [4 /*yield*/, this.applyThemeInternal({})];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * get the theme of the report
     *
     * ```javascript
     * report.getTheme();
     * ```
     */
    Report.prototype.getTheme = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_16;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.get("/report/theme", { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_16 = _a.sent();
                        throw response_16.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Reset user's filters, slicers, and other data view changes to the default state of the report
     *
     * ```javascript
     * report.resetPersistentFilters();
     * ```
     */
    Report.prototype.resetPersistentFilters = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response_17;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.service.hpm.delete("/report/userState", null, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 1: return [2 /*return*/, _a.sent()];
                    case 2:
                        response_17 = _a.sent();
                        throw response_17.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Save user's filters, slicers, and other data view changes of the report
     *
     * ```javascript
     * report.savePersistentFilters();
     * ```
     */
    Report.prototype.savePersistentFilters = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response_18;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.service.hpm.post("/report/userState", null, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 1: return [2 /*return*/, _a.sent()];
                    case 2:
                        response_18 = _a.sent();
                        throw response_18.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Returns if there are user's filters, slicers, or other data view changes applied on the report.
     * If persistent filters is disable, returns false.
     *
     * ```javascript
     * report.arePersistentFiltersApplied();
     * ```
     *
     * @returns {Promise<boolean>}
     */
    Report.prototype.arePersistentFiltersApplied = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_19;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.service.hpm.get("/report/isUserStateApplied", { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_19 = _a.sent();
                        throw response_19.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Remove context menu extension command.
     *
     * ```javascript
     * report.removeContextMenuCommand(commandName, contextMenuTitle)
     *  .catch(error => {
     *      ...
     *  });
     * ```
     *
     * @param {string} commandName
     * @param {string} contextMenuTitle
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.removeContextMenuCommand = function (commandName, contextMenuTitle) {
        return __awaiter(this, void 0, void 0, function () {
            var commandCopy, indexOfCommand, newSetting;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        commandCopy = JSON.parse(JSON.stringify(this.commands));
                        indexOfCommand = this.findCommandMenuIndex("visualContextMenu", commandCopy, commandName, contextMenuTitle);
                        if (indexOfCommand === -1) {
                            throw powerbi_models_1.CommonErrorCodes.NotFound;
                        }
                        // Delete the context menu and not the entire command, since command can have option menu as well.
                        delete commandCopy[indexOfCommand].extend.visualContextMenu;
                        newSetting = {
                            extensions: {
                                commands: commandCopy,
                                groups: this.groups
                            }
                        };
                        return [4 /*yield*/, this.updateSettings(newSetting)];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * Add context menu extension command.
     *
     * ```javascript
     * report.addContextMenuCommand(commandName, commandTitle, contextMenuTitle, menuLocation, visualName, visualType, groupName)
     *  .catch(error => {
     *      ...
     *  });
     * ```
     *
     * @param {string} commandName
     * @param {string} commandTitle
     * @param {string} contextMenuTitle
     * @param {MenuLocation} menuLocation
     * @param {string} visualName
     * @param {string} visualType
     * @param {string} groupName
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.addContextMenuCommand = function (commandName, commandTitle, contextMenuTitle, menuLocation, visualName, visualType, groupName) {
        if (contextMenuTitle === void 0) { contextMenuTitle = commandTitle; }
        if (menuLocation === void 0) { menuLocation = powerbi_models_1.MenuLocation.Bottom; }
        if (visualName === void 0) { visualName = undefined; }
        if (groupName === void 0) { groupName = undefined; }
        return __awaiter(this, void 0, void 0, function () {
            var newCommands, newSetting;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        newCommands = this.createMenuCommand("visualContextMenu", commandName, commandTitle, contextMenuTitle, menuLocation, visualName, visualType, groupName);
                        newSetting = {
                            extensions: {
                                commands: newCommands,
                                groups: this.groups
                            }
                        };
                        return [4 /*yield*/, this.updateSettings(newSetting)];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * Remove options menu extension command.
     *
     * ```javascript
     * report.removeOptionsMenuCommand(commandName, optionsMenuTitle)
     *  .then({
     *      ...
     *  });
     * ```
     *
     * @param {string} commandName
     * @param {string} optionsMenuTitle
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.removeOptionsMenuCommand = function (commandName, optionsMenuTitle) {
        return __awaiter(this, void 0, void 0, function () {
            var commandCopy, indexOfCommand, newSetting;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        commandCopy = JSON.parse(JSON.stringify(this.commands));
                        indexOfCommand = this.findCommandMenuIndex("visualOptionsMenu", commandCopy, commandName, optionsMenuTitle);
                        if (indexOfCommand === -1) {
                            throw powerbi_models_1.CommonErrorCodes.NotFound;
                        }
                        // Delete the context options and not the entire command, since command can have context menu as well.
                        delete commandCopy[indexOfCommand].extend.visualOptionsMenu;
                        delete commandCopy[indexOfCommand].icon;
                        newSetting = {
                            extensions: {
                                commands: commandCopy,
                                groups: this.groups
                            }
                        };
                        return [4 /*yield*/, this.updateSettings(newSetting)];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * Add options menu extension command.
     *
     * ```javascript
     * report.addOptionsMenuCommand(commandName, commandTitle, optionsMenuTitle, menuLocation, visualName, visualType, groupName, commandIcon)
     *  .catch(error => {
     *      ...
     *  });
     * ```
     *
     * @param {string} commandName
     * @param {string} commandTitle
     * @param {string} optionMenuTitle
     * @param {MenuLocation} menuLocation
     * @param {string} visualName
     * @param {string} visualType
     * @param {string} groupName
     * @param {string} commandIcon
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.addOptionsMenuCommand = function (commandName, commandTitle, optionsMenuTitle, menuLocation, visualName, visualType, groupName, commandIcon) {
        if (optionsMenuTitle === void 0) { optionsMenuTitle = commandTitle; }
        if (menuLocation === void 0) { menuLocation = powerbi_models_1.MenuLocation.Bottom; }
        if (visualName === void 0) { visualName = undefined; }
        if (visualType === void 0) { visualType = undefined; }
        if (groupName === void 0) { groupName = undefined; }
        if (commandIcon === void 0) { commandIcon = undefined; }
        return __awaiter(this, void 0, void 0, function () {
            var newCommands, newSetting;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        newCommands = this.createMenuCommand("visualOptionsMenu", commandName, commandTitle, optionsMenuTitle, menuLocation, visualName, visualType, groupName, commandIcon);
                        newSetting = {
                            extensions: {
                                commands: newCommands,
                                groups: this.groups
                            }
                        };
                        return [4 /*yield*/, this.updateSettings(newSetting)];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * Updates the display state of a visual in a page.
     *
     * ```javascript
     * report.setVisualDisplayState(pageName, visualName, displayState)
     *   .catch(error => { ... });
     * ```
     *
     * @param {string} pageName
     * @param {string} visualName
     * @param {VisualContainerDisplayMode} displayState
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.setVisualDisplayState = function (pageName, visualName, displayState) {
        return __awaiter(this, void 0, void 0, function () {
            var visualLayout, newSettings;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: 
                    // Check if page name and visual name are valid
                    return [4 /*yield*/, this.validateVisual(pageName, visualName)];
                    case 1:
                        // Check if page name and visual name are valid
                        _a.sent();
                        visualLayout = {
                            displayState: {
                                mode: displayState
                            }
                        };
                        newSettings = this.buildLayoutSettingsObject(pageName, visualName, visualLayout);
                        return [2 /*return*/, this.updateSettings(newSettings)];
                }
            });
        });
    };
    /**
     * Resize a visual in a page.
     *
     * ```javascript
     * report.resizeVisual(pageName, visualName, width, height)
     *   .catch(error => { ... });
     * ```
     *
     * @param {string} pageName
     * @param {string} visualName
     * @param {number} width
     * @param {number} height
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.resizeVisual = function (pageName, visualName, width, height) {
        return __awaiter(this, void 0, void 0, function () {
            var visualLayout, newSettings;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: 
                    // Check if page name and visual name are valid
                    return [4 /*yield*/, this.validateVisual(pageName, visualName)];
                    case 1:
                        // Check if page name and visual name are valid
                        _a.sent();
                        visualLayout = {
                            width: width,
                            height: height,
                        };
                        newSettings = this.buildLayoutSettingsObject(pageName, visualName, visualLayout);
                        return [2 /*return*/, this.updateSettings(newSettings)];
                }
            });
        });
    };
    /**
     * Updates the size of active page in report.
     *
     * ```javascript
     * report.resizeActivePage(pageSizeType, width, height)
     *   .catch(error => { ... });
     * ```
     *
     * @param {PageSizeType} pageSizeType
     * @param {number} width
     * @param {number} height
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.resizeActivePage = function (pageSizeType, width, height) {
        return __awaiter(this, void 0, void 0, function () {
            var pageSize, newSettings;
            return __generator(this, function (_a) {
                pageSize = {
                    type: pageSizeType,
                    width: width,
                    height: height
                };
                newSettings = {
                    layoutType: powerbi_models_1.LayoutType.Custom,
                    customLayout: {
                        pageSize: pageSize
                    }
                };
                return [2 /*return*/, this.updateSettings(newSettings)];
            });
        });
    };
    /**
     * Updates the position of a visual in a page.
     *
     * ```javascript
     * report.moveVisual(pageName, visualName, x, y, z)
     *   .catch(error => { ... });
     * ```
     *
     * @param {string} pageName
     * @param {string} visualName
     * @param {number} x
     * @param {number} y
     * @param {number} z
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.moveVisual = function (pageName, visualName, x, y, z) {
        return __awaiter(this, void 0, void 0, function () {
            var visualLayout, newSettings;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: 
                    // Check if page name and visual name are valid
                    return [4 /*yield*/, this.validateVisual(pageName, visualName)];
                    case 1:
                        // Check if page name and visual name are valid
                        _a.sent();
                        visualLayout = {
                            x: x,
                            y: y,
                            z: z
                        };
                        newSettings = this.buildLayoutSettingsObject(pageName, visualName, visualLayout);
                        return [2 /*return*/, this.updateSettings(newSettings)];
                }
            });
        });
    };
    /**
     * Updates the report layout
     *
     * ```javascript
     * report.switchLayout(layoutType);
     * ```
     *
     * @param {LayoutType} layoutType
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Report.prototype.switchLayout = function (layoutType) {
        return __awaiter(this, void 0, void 0, function () {
            var isInitialMobileSettings, isPassedMobileSettings, newSetting, response;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        isInitialMobileSettings = this.isMobileSettings({ layoutType: this.initialLayoutType });
                        isPassedMobileSettings = this.isMobileSettings({ layoutType: layoutType });
                        // Check if both passed layout and initial layout are of same type.
                        if (isInitialMobileSettings !== isPassedMobileSettings) {
                            throw "Switching between mobile and desktop layouts is not supported. Please reset the embed container and re-embed with required layout.";
                        }
                        newSetting = {
                            layoutType: layoutType
                        };
                        return [4 /*yield*/, this.updateSettings(newSetting)];
                    case 1:
                        response = _a.sent();
                        this.initialLayoutType = layoutType;
                        return [2 /*return*/, response];
                }
            });
        });
    };
    /**
     * @hidden
     */
    Report.prototype.createMenuCommand = function (type, commandName, commandTitle, menuTitle, menuLocation, visualName, visualType, groupName, icon) {
        var newCommandObj = {
            name: commandName,
            title: commandTitle,
            extend: {}
        };
        newCommandObj.extend[type] = {
            title: menuTitle,
            menuLocation: menuLocation,
        };
        if (type === "visualOptionsMenu") {
            newCommandObj.icon = icon;
        }
        if (groupName) {
            var extend = newCommandObj.extend[type];
            delete extend.menuLocation;
            var groupExtend = newCommandObj.extend[type];
            groupExtend.groupName = groupName;
        }
        if (visualName) {
            newCommandObj.selector = {
                $schema: "http://powerbi.com/product/schema#visualSelector",
                visualName: visualName
            };
        }
        if (visualType) {
            newCommandObj.selector = {
                $schema: "http://powerbi.com/product/schema#visualTypeSelector",
                visualType: visualType
            };
        }
        return __spreadArray(__spreadArray([], this.commands, true), [newCommandObj], false);
    };
    /**
     * @hidden
     */
    Report.prototype.findCommandMenuIndex = function (type, commands, commandName, menuTitle) {
        var indexOfCommand = -1;
        commands.some(function (activeMenuCommand, index) {
            return (activeMenuCommand.name === commandName && activeMenuCommand.extend[type] && activeMenuCommand.extend[type].title === menuTitle) ? (indexOfCommand = index, true) : false;
        });
        return indexOfCommand;
    };
    /**
     * @hidden
     */
    Report.prototype.buildLayoutSettingsObject = function (pageName, visualName, visualLayout) {
        // Create new settings object with custom layout type
        var newSettings = {
            layoutType: powerbi_models_1.LayoutType.Custom,
            customLayout: {
                pagesLayout: {}
            }
        };
        newSettings.customLayout.pagesLayout[pageName] = {
            visualsLayout: {}
        };
        newSettings.customLayout.pagesLayout[pageName].visualsLayout[visualName] = visualLayout;
        return newSettings;
    };
    /**
     * @hidden
     */
    Report.prototype.validateVisual = function (pageName, visualName) {
        return __awaiter(this, void 0, void 0, function () {
            var page;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, this.getPageByName(pageName)];
                    case 1:
                        page = _a.sent();
                        return [4 /*yield*/, page.getVisualByName(visualName)];
                    case 2: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * @hidden
     */
    Report.prototype.applyThemeInternal = function (theme) {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_20;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.service.hpm.put('/report/theme', theme, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_20 = _a.sent();
                        throw response_20.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * @hidden
     */
    Report.prototype.viewModeToString = function (viewMode) {
        var mode;
        switch (viewMode) {
            case powerbi_models_1.ViewMode.Edit:
                mode = "edit";
                break;
            case powerbi_models_1.ViewMode.View:
                mode = "view";
                break;
        }
        return mode;
    };
    /**
     * @hidden
     */
    Report.prototype.isMobileSettings = function (settings) {
        return settings && (settings.layoutType === powerbi_models_1.LayoutType.MobileLandscape || settings.layoutType === powerbi_models_1.LayoutType.MobilePortrait);
    };
    /**
     * Return the current zoom level of the report.
     *
     * @returns {Promise<number>}
     */
    Report.prototype.getZoom = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_21;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.service.hpm.get("/report/zoom", { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_21 = _a.sent();
                        throw response_21.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Sets the report's zoom level.
     *
     * @param zoomLevel zoom level to set
     */
    Report.prototype.setZoom = function (zoomLevel) {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, this.updateSettings({ zoomLevel: zoomLevel })];
                    case 1:
                        _a.sent();
                        return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Closes all open context menus and tooltips.
     *
     * ```javascript
     * report.closeAllOverlays()
     *  .then(() => {
     *      ...
     *  });
     * ```
     *
     * @returns {Promise<void>}
     */
    Report.prototype.closeAllOverlays = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, error_1;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post('/report/closeAllOverlays', null, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        error_1 = _a.sent();
                        return [2 /*return*/, Promise.reject(error_1)];
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Clears selected not popped out visuals, if flag is passed, all visuals selections will be cleared.
     *
     * ```javascript
     * report.clearSelectedVisuals()
     *  .then(() => {
     *      ...
     *  });
     * ```
     *
     * @param {Boolean} [clearPopOutState=false]
     *    If false / undefined visuals selection will not be cleared if one of visuals
     *    is in popped out state (in focus, show as table, spotlight...)
     * @returns {Promise<void>}
     */
    Report.prototype.clearSelectedVisuals = function (clearPopOutState) {
        return __awaiter(this, void 0, void 0, function () {
            var response, error_2;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        clearPopOutState = clearPopOutState === true;
                        if ((0, util_1.isRDLEmbed)(this.config.embedUrl)) {
                            return [2 /*return*/, Promise.reject(errors_1.APINotSupportedForRDLError)];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post("/report/clearSelectedVisuals/".concat(clearPopOutState.toString()), null, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        error_2 = _a.sent();
                        return [2 /*return*/, Promise.reject(error_2)];
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /** @hidden */
    Report.allowedEvents = ["filtersApplied", "pageChanged", "commandTriggered", "swipeStart", "swipeEnd", "bookmarkApplied", "dataHyperlinkClicked", "visualRendered", "visualClicked", "selectionChanged", "renderingStarted", "blur"];
    /** @hidden */
    Report.reportIdAttribute = 'powerbi-report-id';
    /** @hidden */
    Report.filterPaneEnabledAttribute = 'powerbi-settings-filter-pane-enabled';
    /** @hidden */
    Report.navContentPaneEnabledAttribute = 'powerbi-settings-nav-content-pane-enabled';
    /** @hidden */
    Report.typeAttribute = 'powerbi-type';
    /** @hidden */
    Report.type = "Report";
    return Report;
}(embed_1.Embed));
exports.Report = Report;


/***/ }),

/***/ "./src/service.ts":
/*!************************!*\
  !*** ./src/service.ts ***!
  \************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.Service = void 0;
var embed_1 = __webpack_require__(/*! ./embed */ "./src/embed.ts");
var report_1 = __webpack_require__(/*! ./report */ "./src/report.ts");
var create_1 = __webpack_require__(/*! ./create */ "./src/create.ts");
var dashboard_1 = __webpack_require__(/*! ./dashboard */ "./src/dashboard.ts");
var tile_1 = __webpack_require__(/*! ./tile */ "./src/tile.ts");
var page_1 = __webpack_require__(/*! ./page */ "./src/page.ts");
var qna_1 = __webpack_require__(/*! ./qna */ "./src/qna.ts");
var visual_1 = __webpack_require__(/*! ./visual */ "./src/visual.ts");
var utils = __webpack_require__(/*! ./util */ "./src/util.ts");
var quickCreate_1 = __webpack_require__(/*! ./quickCreate */ "./src/quickCreate.ts");
var sdkConfig = __webpack_require__(/*! ./config */ "./src/config.ts");
/**
 * The Power BI Service embed component, which is the entry point to embed all other Power BI components into your application
 *
 * @export
 * @class Service
 * @implements {IService}
 */
var Service = /** @class */ (function () {
    /**
     * Creates an instance of a Power BI Service.
     *
     * @param {IHpmFactory} hpmFactory The http post message factory used in the postMessage communication layer
     * @param {IWpmpFactory} wpmpFactory The window post message factory used in the postMessage communication layer
     * @param {IRouterFactory} routerFactory The router factory used in the postMessage communication layer
     * @param {IServiceConfiguration} [config={}]
     * @hidden
     */
    function Service(hpmFactory, wpmpFactory, routerFactory, config) {
        if (config === void 0) { config = {}; }
        var _this = this;
        /**
         * @hidden
         */
        this.registeredComponents = {};
        this.wpmp = wpmpFactory(config.wpmpName, config.logMessages);
        this.hpm = hpmFactory(this.wpmp, null, config.version, config.type, config.sdkWrapperVersion);
        this.router = routerFactory(this.wpmp);
        this.uniqueSessionId = utils.generateUUID();
        /**
         * Adds handler for report events.
         */
        this.router.post("/reports/:uniqueId/events/:eventName", function (req, _res) {
            var event = {
                type: 'report',
                id: req.params.uniqueId,
                name: req.params.eventName,
                value: req.body
            };
            _this.handleEvent(event);
        });
        this.router.post("/reports/:uniqueId/pages/:pageName/events/:eventName", function (req, _res) {
            var event = {
                type: 'report',
                id: req.params.uniqueId,
                name: req.params.eventName,
                value: req.body
            };
            _this.handleEvent(event);
        });
        this.router.post("/reports/:uniqueId/pages/:pageName/visuals/:visualName/events/:eventName", function (req, _res) {
            var event = {
                type: 'report',
                id: req.params.uniqueId,
                name: req.params.eventName,
                value: req.body
            };
            _this.handleEvent(event);
        });
        this.router.post("/dashboards/:uniqueId/events/:eventName", function (req, _res) {
            var event = {
                type: 'dashboard',
                id: req.params.uniqueId,
                name: req.params.eventName,
                value: req.body
            };
            _this.handleEvent(event);
        });
        this.router.post("/tile/:uniqueId/events/:eventName", function (req, _res) {
            var event = {
                type: 'tile',
                id: req.params.uniqueId,
                name: req.params.eventName,
                value: req.body
            };
            _this.handleEvent(event);
        });
        /**
         * Adds handler for Q&A events.
         */
        this.router.post("/qna/:uniqueId/events/:eventName", function (req, _res) {
            var event = {
                type: 'qna',
                id: req.params.uniqueId,
                name: req.params.eventName,
                value: req.body
            };
            _this.handleEvent(event);
        });
        /**
         * Adds handler for front load 'ready' message.
         */
        this.router.post("/ready/:uniqueId", function (req, _res) {
            var event = {
                type: 'report',
                id: req.params.uniqueId,
                name: 'ready',
                value: req.body
            };
            _this.handleEvent(event);
        });
        this.embeds = [];
        // TODO: Change when Object.assign is available.
        this.config = utils.assign({}, Service.defaultConfig, config);
        if (this.config.autoEmbedOnContentLoaded) {
            this.enableAutoEmbed();
        }
    }
    /**
     * Creates new report
     *
     * @param {HTMLElement} element
     * @param {IEmbedConfiguration} [config={}]
     * @returns {Embed}
     */
    Service.prototype.createReport = function (element, config) {
        config.type = 'create';
        var powerBiElement = element;
        var component = new create_1.Create(this, powerBiElement, config);
        powerBiElement.powerBiEmbed = component;
        this.addOrOverwriteEmbed(component, element);
        return component;
    };
    /**
     * Creates new dataset
     *
     * @param {HTMLElement} element
     * @param {IEmbedConfiguration} [config={}]
     * @returns {Embed}
     */
    Service.prototype.quickCreate = function (element, config) {
        config.type = 'quickCreate';
        var powerBiElement = element;
        var component = new quickCreate_1.QuickCreate(this, powerBiElement, config);
        powerBiElement.powerBiEmbed = component;
        this.addOrOverwriteEmbed(component, element);
        return component;
    };
    /**
     * TODO: Add a description here
     *
     * @param {HTMLElement} [container]
     * @param {IEmbedConfiguration} [config=undefined]
     * @returns {Embed[]}
     * @hidden
     */
    Service.prototype.init = function (container, config) {
        var _this = this;
        if (config === void 0) { config = undefined; }
        container = (container && container instanceof HTMLElement) ? container : document.body;
        var elements = Array.prototype.slice.call(container.querySelectorAll("[".concat(embed_1.Embed.embedUrlAttribute, "]")));
        return elements.map(function (element) { return _this.embed(element, config); });
    };
    /**
     * Given a configuration based on an HTML element,
     * if the component has already been created and attached to the element, reuses the component instance and existing iframe,
     * otherwise creates a new component instance.
     *
     * @param {HTMLElement} element
     * @param {IEmbedConfigurationBase} [config={}]
     * @returns {Embed}
     */
    Service.prototype.embed = function (element, config) {
        if (config === void 0) { config = {}; }
        return this.embedInternal(element, config);
    };
    /**
     * Given a configuration based on an HTML element,
     * if the component has already been created and attached to the element, reuses the component instance and existing iframe,
     * otherwise creates a new component instance.
     * This is used for the phased embedding API, once element is loaded successfully, one can call 'render' on it.
     *
     * @param {HTMLElement} element
     * @param {IEmbedConfigurationBase} [config={}]
     * @returns {Embed}
     */
    Service.prototype.load = function (element, config) {
        if (config === void 0) { config = {}; }
        return this.embedInternal(element, config, /* phasedRender */ true, /* isBootstrap */ false);
    };
    /**
     * Given an HTML element and entityType, creates a new component instance, and bootstrap the iframe for embedding.
     *
     * @param {HTMLElement} element
     * @param {IBootstrapEmbedConfiguration} config: a bootstrap config which is an embed config without access token.
     */
    Service.prototype.bootstrap = function (element, config) {
        return this.embedInternal(element, config, /* phasedRender */ false, /* isBootstrap */ true);
    };
    /** @hidden */
    Service.prototype.embedInternal = function (element, config, phasedRender, isBootstrap) {
        if (config === void 0) { config = {}; }
        var component;
        var powerBiElement = element;
        if (powerBiElement.powerBiEmbed) {
            if (isBootstrap) {
                throw new Error("Attempted to bootstrap element ".concat(element.outerHTML, ", but the element is already a powerbi element."));
            }
            component = this.embedExisting(powerBiElement, config, phasedRender);
        }
        else {
            component = this.embedNew(powerBiElement, config, phasedRender, isBootstrap);
        }
        return component;
    };
    /** @hidden */
    Service.prototype.getNumberOfComponents = function () {
        if (!this.embeds) {
            return 0;
        }
        return this.embeds.length;
    };
    /** @hidden */
    Service.prototype.getSdkSessionId = function () {
        return this.uniqueSessionId;
    };
    /**
     * Returns the Power BI Client SDK version
     *
     * @hidden
     */
    Service.prototype.getSDKVersion = function () {
        return sdkConfig.default.version;
    };
    /**
     * Given a configuration based on a Power BI element, saves the component instance that reference the element for later lookup.
     *
     * @private
     * @param {IPowerBiElement} element
     * @param {IEmbedConfigurationBase} config
     * @param {boolean} phasedRender
     * @param {boolean} isBootstrap
     * @returns {Embed}
     * @hidden
     */
    Service.prototype.embedNew = function (element, config, phasedRender, isBootstrap) {
        var componentType = config.type || element.getAttribute(embed_1.Embed.typeAttribute);
        if (!componentType) {
            var scrubbedConfig = __assign(__assign({}, config), { accessToken: "" });
            throw new Error("Attempted to embed using config ".concat(JSON.stringify(scrubbedConfig), " on element ").concat(element.outerHTML, ", but could not determine what type of component to embed. You must specify a type in the configuration or as an attribute such as '").concat(embed_1.Embed.typeAttribute, "=\"").concat(report_1.Report.type.toLowerCase(), "\"'."));
        }
        // Saves the type as part of the configuration so that it can be referenced later at a known location.
        config.type = componentType;
        var component = this.createEmbedComponent(componentType, element, config, phasedRender, isBootstrap);
        element.powerBiEmbed = component;
        this.addOrOverwriteEmbed(component, element);
        return component;
    };
    /**
     * Given component type, creates embed component instance
     *
     * @private
     * @param {string} componentType
     * @param {HTMLElement} element
     * @param {IEmbedConfigurationBase} config
     * @param {boolean} phasedRender
     * @param {boolean} isBootstrap
     * @returns {Embed}
     * @hidden
     */
    Service.prototype.createEmbedComponent = function (componentType, element, config, phasedRender, isBootstrap) {
        var Component = utils.find(function (embedComponent) { return componentType === embedComponent.type.toLowerCase(); }, Service.components);
        if (Component) {
            return new Component(this, element, config, phasedRender, isBootstrap);
        }
        // If component type is not legacy, search in registered components
        var registeredComponent = utils.find(function (registeredComponentType) { return componentType.toLowerCase() === registeredComponentType.toLowerCase(); }, Object.keys(this.registeredComponents));
        if (!registeredComponent) {
            throw new Error("Attempted to embed component of type: ".concat(componentType, " but did not find any matching component.  Please verify the type you specified is intended."));
        }
        return this.registeredComponents[registeredComponent](this, element, config, phasedRender, isBootstrap);
    };
    /**
     * Given an element that already contains an embed component, load with a new configuration.
     *
     * @private
     * @param {IPowerBiElement} element
     * @param {IEmbedConfigurationBase} config
     * @returns {Embed}
     * @hidden
     */
    Service.prototype.embedExisting = function (element, config, phasedRender) {
        var component = utils.find(function (x) { return x.element === element; }, this.embeds);
        if (!component) {
            var scrubbedConfig = __assign(__assign({}, config), { accessToken: "" });
            throw new Error("Attempted to embed using config ".concat(JSON.stringify(scrubbedConfig), " on element ").concat(element.outerHTML, " which already has embedded component associated, but could not find the existing component in the list of active components. This could indicate the embeds list is out of sync with the DOM, or the component is referencing the incorrect HTML element."));
        }
        // TODO: Multiple embedding to the same iframe is not supported in QnA
        if (config.type && config.type.toLowerCase() === "qna") {
            return this.embedNew(element, config);
        }
        /**
         * TODO: Dynamic embed type switching could be supported but there is work needed to prepare the service state and DOM cleanup.
         * remove all event handlers from the DOM, then reset the element to initial state which removes iframe, and removes from list of embeds
         * then we can call the embedNew function which would allow setting the proper embedUrl and construction of object based on the new type.
         */
        if (typeof config.type === "string" && config.type !== component.config.type) {
            /**
             * When loading report after create we want to use existing Iframe to optimize load period
             */
            if (config.type === "report" && utils.isCreate(component.config.type)) {
                var report = new report_1.Report(this, element, config, /* phasedRender */ false, /* isBootstrap */ false, element.powerBiEmbed.iframe);
                component.populateConfig(config, /* isBootstrap */ false);
                report.load();
                element.powerBiEmbed = report;
                this.addOrOverwriteEmbed(component, element);
                return report;
            }
            var scrubbedConfig = __assign(__assign({}, config), { accessToken: "" });
            throw new Error("Embedding on an existing element with a different type than the previous embed object is not supported.  Attempted to embed using config ".concat(JSON.stringify(scrubbedConfig), " on element ").concat(element.outerHTML, ", but the existing element contains an embed of type: ").concat(this.config.type, " which does not match the new type: ").concat(config.type));
        }
        component.populateConfig(config, /* isBootstrap */ false);
        component.load(phasedRender);
        return component;
    };
    /**
     * Adds an event handler for DOMContentLoaded, which searches the DOM for elements that have the 'powerbi-embed-url' attribute,
     * and automatically attempts to embed a powerbi component based on information from other powerbi-* attributes.
     *
     * Note: Only runs if `config.autoEmbedOnContentLoaded` is true when the service is created.
     * This handler is typically useful only for applications that are rendered on the server so that all required data is available when the handler is called.
     *
     * @hidden
     */
    Service.prototype.enableAutoEmbed = function () {
        var _this = this;
        window.addEventListener('DOMContentLoaded', function (_event) { return _this.init(document.body); }, false);
    };
    /**
     * Returns an instance of the component associated with the element.
     *
     * @param {HTMLElement} element
     * @returns {(Report | Tile)}
     */
    Service.prototype.get = function (element) {
        var powerBiElement = element;
        if (!powerBiElement.powerBiEmbed) {
            throw new Error("You attempted to get an instance of powerbi component associated with element: ".concat(element.outerHTML, " but there was no associated instance."));
        }
        return powerBiElement.powerBiEmbed;
    };
    /**
     * Finds an embed instance by the name or unique ID that is provided.
     *
     * @param {string} uniqueId
     * @returns {(Report | Tile)}
     * @hidden
     */
    Service.prototype.find = function (uniqueId) {
        return utils.find(function (x) { return x.config.uniqueId === uniqueId; }, this.embeds);
    };
    /**
     * Removes embed components whose container element is same as the given element
     *
     * @param {Embed} component
     * @param {HTMLElement} element
     * @returns {void}
     * @hidden
     */
    Service.prototype.addOrOverwriteEmbed = function (component, element) {
        // remove embeds over the same div element.
        this.embeds = this.embeds.filter(function (embed) {
            return embed.element !== element;
        });
        this.embeds.push(component);
    };
    /**
     * Given an HTML element that has a component embedded within it, removes the component from the list of embedded components, removes the association between the element and the component, and removes the iframe.
     *
     * @param {HTMLElement} element
     * @returns {void}
     */
    Service.prototype.reset = function (element) {
        var powerBiElement = element;
        if (!powerBiElement.powerBiEmbed) {
            return;
        }
        /** Removes the element frontLoad listener if exists. */
        var embedElement = powerBiElement.powerBiEmbed;
        if (embedElement.frontLoadHandler) {
            embedElement.element.removeEventListener('ready', embedElement.frontLoadHandler, false);
        }
        /** Removes all event handlers. */
        embedElement.allowedEvents.forEach(function (eventName) {
            embedElement.off(eventName);
        });
        /** Removes the component from an internal list of components. */
        utils.remove(function (x) { return x === powerBiElement.powerBiEmbed; }, this.embeds);
        /** Deletes a property from the HTML element. */
        delete powerBiElement.powerBiEmbed;
        /** Removes the iframe from the element. */
        var iframe = element.querySelector('iframe');
        if (iframe) {
            if (iframe.remove !== undefined) {
                iframe.remove();
            }
            else {
                /** Workaround for IE: unhandled rejection TypeError: object doesn't support property or method 'remove' */
                iframe.parentElement.removeChild(iframe);
            }
        }
    };
    /**
     * handles tile events
     *
     * @param {IEvent<any>} event
     * @hidden
     */
    Service.prototype.handleTileEvents = function (event) {
        if (event.type === 'tile') {
            this.handleEvent(event);
        }
    };
    Service.prototype.invokeSDKHook = function (hook, req, res) {
        return __awaiter(this, void 0, void 0, function () {
            var result, error_1;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if (!hook) {
                            res.send(404, null);
                            return [2 /*return*/];
                        }
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, hook(req.body)];
                    case 2:
                        result = _a.sent();
                        res.send(200, result);
                        return [3 /*break*/, 4];
                    case 3:
                        error_1 = _a.sent();
                        res.send(400, null);
                        console.error(error_1);
                        return [3 /*break*/, 4];
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Given an event object, finds the embed component with the matching type and ID, and invokes its handleEvent method with the event object.
     *
     * @private
     * @param {IEvent<any>} event
     * @hidden
     */
    Service.prototype.handleEvent = function (event) {
        var embed = utils.find(function (embed) {
            return (embed.config.uniqueId === event.id);
        }, this.embeds);
        if (embed) {
            var value = event.value;
            if (event.name === 'pageChanged') {
                var pageKey = 'newPage';
                var page = value[pageKey];
                if (!page) {
                    throw new Error("Page model not found at 'event.value.".concat(pageKey, "'."));
                }
                value[pageKey] = new page_1.Page(embed, page.name, page.displayName, true /* isActive */);
            }
            utils.raiseCustomEvent(embed.element, event.name, value);
        }
    };
    /**
     * API for warm starting powerbi embedded endpoints.
     * Use this API to preload Power BI Embedded in the background.
     *
     * @public
     * @param {IEmbedConfigurationBase} [config={}]
     * @param {HTMLElement} [element=undefined]
     */
    Service.prototype.preload = function (config, element) {
        var iframeContent = document.createElement("iframe");
        iframeContent.setAttribute("style", "display:none;");
        iframeContent.setAttribute("src", config.embedUrl);
        iframeContent.setAttribute("scrolling", "no");
        iframeContent.setAttribute("allowfullscreen", "false");
        var node = element;
        if (!node) {
            node = document.getElementsByTagName("body")[0];
        }
        node.appendChild(iframeContent);
        iframeContent.onload = function () {
            utils.raiseCustomEvent(iframeContent, "preloaded", {});
        };
        return iframeContent;
    };
    /**
     * Use this API to set SDK info
     *
     * @hidden
     * @param {string} type
     * @returns {void}
     */
    Service.prototype.setSdkInfo = function (type, version) {
        this.hpm.defaultHeaders['x-sdk-type'] = type;
        this.hpm.defaultHeaders['x-sdk-wrapper-version'] = version;
    };
    /**
     * API for registering external components
     *
     * @hidden
     * @param {string} componentType
     * @param {EmbedComponentFactory} embedComponentFactory
     * @param {string[]} routerEventUrls
     */
    Service.prototype.register = function (componentType, embedComponentFactory, routerEventUrls) {
        var _this = this;
        if (utils.find(function (embedComponent) { return componentType.toLowerCase() === embedComponent.type.toLowerCase(); }, Service.components)) {
            throw new Error('The component name is reserved. Cannot register a component with this name.');
        }
        if (utils.find(function (registeredComponentType) { return componentType.toLowerCase() === registeredComponentType.toLowerCase(); }, Object.keys(this.registeredComponents))) {
            throw new Error('A component with this type is already registered.');
        }
        this.registeredComponents[componentType] = embedComponentFactory;
        routerEventUrls.forEach(function (url) {
            if (!url.includes(':uniqueId') || !url.includes(':eventName')) {
                throw new Error('Invalid router event URL');
            }
            _this.router.post(url, function (req, _res) {
                var event = {
                    type: componentType,
                    id: req.params.uniqueId,
                    name: req.params.eventName,
                    value: req.body
                };
                _this.handleEvent(event);
            });
        });
    };
    /**
     * A list of components that this service can embed
     */
    Service.components = [
        tile_1.Tile,
        report_1.Report,
        dashboard_1.Dashboard,
        qna_1.Qna,
        visual_1.Visual
    ];
    /**
     * The default configuration for the service
     */
    Service.defaultConfig = {
        autoEmbedOnContentLoaded: false,
        onError: function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            return console.log(args[0], args.slice(1));
        }
    };
    return Service;
}());
exports.Service = Service;


/***/ }),

/***/ "./src/tile.ts":
/*!*********************!*\
  !*** ./src/tile.ts ***!
  \*********************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.Tile = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var embed_1 = __webpack_require__(/*! ./embed */ "./src/embed.ts");
/**
 * The Power BI tile embed component
 *
 * @export
 * @class Tile
 * @extends {Embed}
 */
var Tile = /** @class */ (function (_super) {
    __extends(Tile, _super);
    /**
     * @hidden
     */
    function Tile(service, element, baseConfig, phasedRender, isBootstrap) {
        var _this = this;
        var config = baseConfig;
        _this = _super.call(this, service, element, config, /* iframe */ undefined, phasedRender, isBootstrap) || this;
        _this.loadPath = "/tile/load";
        Array.prototype.push.apply(_this.allowedEvents, Tile.allowedEvents);
        return _this;
    }
    /**
     * The ID of the tile
     *
     * @returns {string}
     */
    Tile.prototype.getId = function () {
        var config = this.config;
        var tileId = config.id || Tile.findIdFromEmbedUrl(this.config.embedUrl);
        if (typeof tileId !== 'string' || tileId.length === 0) {
            throw new Error("Tile id is required, but it was not found. You must provide an id either as part of embed configuration.");
        }
        return tileId;
    };
    /**
     * Validate load configuration.
     */
    Tile.prototype.validate = function (config) {
        var embedConfig = config;
        return (0, powerbi_models_1.validateTileLoad)(embedConfig);
    };
    /**
     * Handle config changes.
     *
     * @returns {void}
     */
    Tile.prototype.configChanged = function (isBootstrap) {
        if (isBootstrap) {
            return;
        }
        // Populate tile id into config object.
        this.config.id = this.getId();
    };
    /**
     * @hidden
     * @returns {string}
     */
    Tile.prototype.getDefaultEmbedUrlEndpoint = function () {
        return "tileEmbed";
    };
    /**
     * Adds the ability to get tileId from url.
     * By extracting the ID we can ensure that the ID is always explicitly provided as part of the load configuration.
     *
     * @hidden
     * @static
     * @param {string} url
     * @returns {string}
     */
    Tile.findIdFromEmbedUrl = function (url) {
        var tileIdRegEx = /tileId="?([^&]+)"?/;
        var tileIdMatch = url.match(tileIdRegEx);
        var tileId;
        if (tileIdMatch) {
            tileId = tileIdMatch[1];
        }
        return tileId;
    };
    /** @hidden */
    Tile.type = "Tile";
    /** @hidden */
    Tile.allowedEvents = ["tileClicked", "tileLoaded"];
    return Tile;
}(embed_1.Embed));
exports.Tile = Tile;


/***/ }),

/***/ "./src/util.ts":
/*!*********************!*\
  !*** ./src/util.ts ***!
  \*********************/
/***/ (function(__unused_webpack_module, exports) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.isCreate = exports.getTimeDiffInMilliseconds = exports.getRandomValue = exports.autoAuthInEmbedUrl = exports.isRDLEmbed = exports.isSavedInternal = exports.addParamToUrl = exports.generateUUID = exports.createRandomString = exports.assign = exports.remove = exports.find = exports.findIndex = exports.raiseCustomEvent = void 0;
/**
 * Raises a custom event with event data on the specified HTML element.
 *
 * @export
 * @param {HTMLElement} element
 * @param {string} eventName
 * @param {*} eventData
 */
function raiseCustomEvent(element, eventName, eventData) {
    var customEvent;
    if (typeof CustomEvent === 'function') {
        customEvent = new CustomEvent(eventName, {
            detail: eventData,
            bubbles: true,
            cancelable: true
        });
    }
    else {
        customEvent = document.createEvent('CustomEvent');
        customEvent.initCustomEvent(eventName, true, true, eventData);
    }
    element.dispatchEvent(customEvent);
}
exports.raiseCustomEvent = raiseCustomEvent;
/**
 * Finds the index of the first value in an array that matches the specified predicate.
 *
 * @export
 * @template T
 * @param {(x: T) => boolean} predicate
 * @param {T[]} xs
 * @returns {number}
 */
function findIndex(predicate, xs) {
    if (!Array.isArray(xs)) {
        throw new Error("You attempted to call find with second parameter that was not an array. You passed: ".concat(xs));
    }
    var index;
    xs.some(function (x, i) {
        if (predicate(x)) {
            index = i;
            return true;
        }
    });
    return index;
}
exports.findIndex = findIndex;
/**
 * Finds the first value in an array that matches the specified predicate.
 *
 * @export
 * @template T
 * @param {(x: T) => boolean} predicate
 * @param {T[]} xs
 * @returns {T}
 */
function find(predicate, xs) {
    var index = findIndex(predicate, xs);
    return xs[index];
}
exports.find = find;
function remove(predicate, xs) {
    var index = findIndex(predicate, xs);
    xs.splice(index, 1);
}
exports.remove = remove;
// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/assign
// TODO: replace in favor of using polyfill
/**
 * Copies the values of all enumerable properties from one or more source objects to a target object, and returns the target object.
 *
 * @export
 * @param {any} args
 * @returns
 */
function assign() {
    var args = [];
    for (var _i = 0; _i < arguments.length; _i++) {
        args[_i] = arguments[_i];
    }
    var target = args[0];
    'use strict';
    if (target === undefined || target === null) {
        throw new TypeError('Cannot convert undefined or null to object');
    }
    var output = Object(target);
    for (var index = 1; index < arguments.length; index++) {
        var source = arguments[index];
        if (source !== undefined && source !== null) {
            for (var nextKey in source) {
                if (source.hasOwnProperty(nextKey)) {
                    output[nextKey] = source[nextKey];
                }
            }
        }
    }
    return output;
}
exports.assign = assign;
/**
 * Generates a random 5 to 6 character string.
 *
 * @export
 * @returns {string}
 */
function createRandomString() {
    return getRandomValue().toString(36).substring(1);
}
exports.createRandomString = createRandomString;
/**
 * Generates a 20 character uuid.
 *
 * @export
 * @returns {string}
 */
function generateUUID() {
    var d = new Date().getTime();
    if (typeof performance !== 'undefined' && typeof performance.now === 'function') {
        d += performance.now();
    }
    return 'xxxxxxxxxxxxxxxxxxxx'.replace(/[xy]/g, function (_c) {
        // Generate a random number, scaled from 0 to 15.
        var r = (getRandomValue() % 16);
        // Shift 4 times to divide by 16
        d >>= 4;
        return r.toString(16);
    });
}
exports.generateUUID = generateUUID;
/**
 * Adds a parameter to the given url
 *
 * @export
 * @param {string} url
 * @param {string} paramName
 * @param {string} value
 * @returns {string}
 */
function addParamToUrl(url, paramName, value) {
    var parameterPrefix = url.indexOf('?') > 0 ? '&' : '?';
    url += parameterPrefix + paramName + '=' + value;
    return url;
}
exports.addParamToUrl = addParamToUrl;
/**
 * Checks if the report is saved.
 *
 * @export
 * @param {HttpPostMessage} hpm
 * @param {string} uid
 * @param {Window} contentWindow
 * @returns {Promise<boolean>}
 */
function isSavedInternal(hpm, uid, contentWindow) {
    return __awaiter(this, void 0, void 0, function () {
        var response, response_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 2, , 3]);
                    return [4 /*yield*/, hpm.get('/report/hasUnsavedChanges', { uid: uid }, contentWindow)];
                case 1:
                    response = _a.sent();
                    return [2 /*return*/, !response.body];
                case 2:
                    response_1 = _a.sent();
                    throw response_1.body;
                case 3: return [2 /*return*/];
            }
        });
    });
}
exports.isSavedInternal = isSavedInternal;
/**
 * Checks if the embed url is for RDL report.
 *
 * @export
 * @param {string} embedUrl
 * @returns {boolean}
 */
function isRDLEmbed(embedUrl) {
    return embedUrl && embedUrl.toLowerCase().indexOf("/rdlembed?") >= 0;
}
exports.isRDLEmbed = isRDLEmbed;
/**
 * Checks if the embed url contains autoAuth=true.
 *
 * @export
 * @param {string} embedUrl
 * @returns {boolean}
 */
function autoAuthInEmbedUrl(embedUrl) {
    return embedUrl && decodeURIComponent(embedUrl).toLowerCase().indexOf("autoauth=true") >= 0;
}
exports.autoAuthInEmbedUrl = autoAuthInEmbedUrl;
/**
 * Returns random number
 */
function getRandomValue() {
    // window.msCrypto for IE
    var cryptoObj = window.crypto || window.msCrypto;
    var randomValueArray = new Uint32Array(1);
    cryptoObj.getRandomValues(randomValueArray);
    return randomValueArray[0];
}
exports.getRandomValue = getRandomValue;
/**
 * Returns the time interval between two dates in milliseconds
 *
 * @export
 * @param {Date} start
 * @param {Date} end
 * @returns {number}
 */
function getTimeDiffInMilliseconds(start, end) {
    return Math.abs(start.getTime() - end.getTime());
}
exports.getTimeDiffInMilliseconds = getTimeDiffInMilliseconds;
/**
 * Checks if the embed type is for create
 *
 * @export
 * @param {string} embedType
 * @returns {boolean}
 */
function isCreate(embedType) {
    return embedType === 'create' || embedType === 'quickcreate';
}
exports.isCreate = isCreate;


/***/ }),

/***/ "./src/visual.ts":
/*!***********************!*\
  !*** ./src/visual.ts ***!
  \***********************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.Visual = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
var report_1 = __webpack_require__(/*! ./report */ "./src/report.ts");
var visualDescriptor_1 = __webpack_require__(/*! ./visualDescriptor */ "./src/visualDescriptor.ts");
/**
 * The Power BI Visual embed component
 *
 * @export
 * @class Visual
 */
var Visual = /** @class */ (function (_super) {
    __extends(Visual, _super);
    /**
     * Creates an instance of a Power BI Single Visual.
     *
     * @param {Service} service
     * @param {HTMLElement} element
     * @param {IEmbedConfiguration} config
     * @hidden
     */
    function Visual(service, element, baseConfig, phasedRender, isBootstrap, iframe) {
        return _super.call(this, service, element, baseConfig, phasedRender, isBootstrap, iframe) || this;
    }
    /**
     * @hidden
     */
    Visual.prototype.load = function (phasedRender) {
        var config = this.config;
        if (!config.accessToken) {
            // bootstrap flow.
            return;
        }
        if (typeof config.pageName !== 'string' || config.pageName.length === 0) {
            throw new Error("Page name is required when embedding a visual.");
        }
        if (typeof config.visualName !== 'string' || config.visualName.length === 0) {
            throw new Error("Visual name is required, but it was not found. You must provide a visual name as part of embed configuration.");
        }
        // calculate custom layout settings and override config.
        var width = config.width ? config.width : this.iframe.offsetWidth;
        var height = config.height ? config.height : this.iframe.offsetHeight;
        var pageSize = {
            type: powerbi_models_1.PageSizeType.Custom,
            width: width,
            height: height,
        };
        var pagesLayout = {};
        pagesLayout[config.pageName] = {
            defaultLayout: {
                displayState: {
                    mode: powerbi_models_1.VisualContainerDisplayMode.Hidden
                }
            },
            visualsLayout: {}
        };
        pagesLayout[config.pageName].visualsLayout[config.visualName] = {
            displayState: {
                mode: powerbi_models_1.VisualContainerDisplayMode.Visible
            },
            x: 1,
            y: 1,
            z: 1,
            width: pageSize.width,
            height: pageSize.height
        };
        config.settings = config.settings || {};
        config.settings.filterPaneEnabled = false;
        config.settings.navContentPaneEnabled = false;
        config.settings.layoutType = powerbi_models_1.LayoutType.Custom;
        config.settings.customLayout = {
            displayOption: powerbi_models_1.DisplayOption.FitToPage,
            pageSize: pageSize,
            pagesLayout: pagesLayout
        };
        this.config = config;
        return _super.prototype.load.call(this, phasedRender);
    };
    /**
     * Gets the list of pages within the report - not supported in visual
     *
     * @returns {Promise<Page[]>}
     */
    Visual.prototype.getPages = function () {
        throw Visual.GetPagesNotSupportedError;
    };
    /**
     * Sets the active page of the report - not supported in visual
     *
     * @param {string} pageName
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Visual.prototype.setPage = function (_pageName) {
        throw Visual.SetPageNotSupportedError;
    };
    /**
     * Render a preloaded report, using phased embedding API
     *
     * @hidden
     * @returns {Promise<void>}
     */
    Visual.prototype.render = function (_config) {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                throw Visual.RenderNotSupportedError;
            });
        });
    };
    /**
     * Gets the embedded visual descriptor object that contains the visual name, type, etc.
     *
     * ```javascript
     * visual.getVisualDescriptor()
     *   .then(visualDetails => { ... });
     * ```
     *
     * @returns {Promise<VisualDescriptor>}
     */
    Visual.prototype.getVisualDescriptor = function () {
        return __awaiter(this, void 0, void 0, function () {
            var config, response, embeddedVisuals, visualNotFoundError, embeddedVisual, currentPage, response_1;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        config = this.config;
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.get("/report/pages/".concat(config.pageName, "/visuals"), { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        embeddedVisuals = response.body.filter(function (pageVisual) { return pageVisual.name === config.visualName; });
                        if (embeddedVisuals.length === 0) {
                            visualNotFoundError = {
                                message: "visualNotFound",
                                detailedMessage: "Visual not found"
                            };
                            throw visualNotFoundError;
                        }
                        embeddedVisual = embeddedVisuals[0];
                        currentPage = this.page(config.pageName);
                        return [2 /*return*/, new visualDescriptor_1.VisualDescriptor(currentPage, embeddedVisual.name, embeddedVisual.title, embeddedVisual.type, embeddedVisual.layout)];
                    case 3:
                        response_1 = _a.sent();
                        throw response_1.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Gets filters that are applied to the filter level.
     * Default filter level is visual level.
     *
     * ```javascript
     * visual.getFilters(filtersLevel)
     *   .then(filters => {
     *     ...
     *   });
     * ```
     *
     * @returns {Promise<IFilter[]>}
     */
    Visual.prototype.getFilters = function (filtersLevel) {
        return __awaiter(this, void 0, void 0, function () {
            var url, response, response_2;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        url = this.getFiltersLevelUrl(filtersLevel);
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.get(url, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_2 = _a.sent();
                        throw response_2.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Updates filters at the filter level.
     * Default filter level is visual level.
     *
     * ```javascript
     * const filters: [
     *    ...
     * ];
     *
     * visual.updateFilters(FiltersOperations.Add, filters, filtersLevel)
     *  .catch(errors => {
     *    ...
     *  });
     * ```
     *
     * @param {(IFilter[])} filters
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Visual.prototype.updateFilters = function (operation, filters, filtersLevel) {
        return __awaiter(this, void 0, void 0, function () {
            var updateFiltersRequest, url, response_3;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        updateFiltersRequest = {
                            filtersOperation: operation,
                            filters: filters
                        };
                        url = this.getFiltersLevelUrl(filtersLevel);
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.post(url, updateFiltersRequest, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_3 = _a.sent();
                        throw response_3.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Sets filters at the filter level.
     * Default filter level is visual level.
     *
     * ```javascript
     * const filters: [
     *    ...
     * ];
     *
     * visual.setFilters(filters, filtersLevel)
     *  .catch(errors => {
     *    ...
     *  });
     * ```
     *
     * @param {(IFilter[])} filters
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Visual.prototype.setFilters = function (filters, filtersLevel) {
        return __awaiter(this, void 0, void 0, function () {
            var url, response_4;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        url = this.getFiltersLevelUrl(filtersLevel);
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.service.hpm.put(url, filters, { uid: this.config.uniqueId }, this.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_4 = _a.sent();
                        throw response_4.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Removes all filters from the current filter level.
     * Default filter level is visual level.
     *
     * ```javascript
     * visual.removeFilters(filtersLevel);
     * ```
     *
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    Visual.prototype.removeFilters = function (filtersLevel) {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, this.updateFilters(powerbi_models_1.FiltersOperations.RemoveAll, undefined, filtersLevel)];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * @hidden
     */
    Visual.prototype.getFiltersLevelUrl = function (filtersLevel) {
        var config = this.config;
        switch (filtersLevel) {
            case powerbi_models_1.FiltersLevel.Report:
                return "/report/filters";
            case powerbi_models_1.FiltersLevel.Page:
                return "/report/pages/".concat(config.pageName, "/filters");
            default:
                return "/report/pages/".concat(config.pageName, "/visuals/").concat(config.visualName, "/filters");
        }
    };
    /** @hidden */
    Visual.type = "visual";
    /** @hidden */
    Visual.GetPagesNotSupportedError = "Get pages is not supported while embedding a visual.";
    /** @hidden */
    Visual.SetPageNotSupportedError = "Set page is not supported while embedding a visual.";
    /** @hidden */
    Visual.RenderNotSupportedError = "render is not supported while embedding a visual.";
    return Visual;
}(report_1.Report));
exports.Visual = Visual;


/***/ }),

/***/ "./src/visualDescriptor.ts":
/*!*********************************!*\
  !*** ./src/visualDescriptor.ts ***!
  \*********************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.VisualDescriptor = void 0;
var powerbi_models_1 = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
/**
 * A Power BI visual within a page
 *
 * @export
 * @class VisualDescriptor
 * @implements {IVisualNode}
 */
var VisualDescriptor = /** @class */ (function () {
    /**
     * @hidden
     */
    function VisualDescriptor(page, name, title, type, layout) {
        this.name = name;
        this.title = title;
        this.type = type;
        this.layout = layout;
        this.page = page;
    }
    /**
     * Gets all visual level filters of the current visual.
     *
     * ```javascript
     * visual.getFilters()
     *  .then(filters => { ... });
     * ```
     *
     * @returns {(Promise<IFilter[]>)}
     */
    VisualDescriptor.prototype.getFilters = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_1;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.page.report.service.hpm.get("/report/pages/".concat(this.page.name, "/visuals/").concat(this.name, "/filters"), { uid: this.page.report.config.uniqueId }, this.page.report.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_1 = _a.sent();
                        throw response_1.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Update the filters for the current visual according to the operation: Add, replace all, replace by target or remove.
     *
     * ```javascript
     * visual.updateFilters(FiltersOperations.Add, filters)
     *   .catch(errors => { ... });
     * ```
     *
     * @param {(IFilter[])} filters
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    VisualDescriptor.prototype.updateFilters = function (operation, filters) {
        return __awaiter(this, void 0, void 0, function () {
            var updateFiltersRequest, response_2;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        updateFiltersRequest = {
                            filtersOperation: operation,
                            filters: filters
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.page.report.service.hpm.post("/report/pages/".concat(this.page.name, "/visuals/").concat(this.name, "/filters"), updateFiltersRequest, { uid: this.page.report.config.uniqueId }, this.page.report.iframe.contentWindow)];
                    case 2: return [2 /*return*/, _a.sent()];
                    case 3:
                        response_2 = _a.sent();
                        throw response_2.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Removes all filters from the current visual.
     *
     * ```javascript
     * visual.removeFilters();
     * ```
     *
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    VisualDescriptor.prototype.removeFilters = function () {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, this.updateFilters(powerbi_models_1.FiltersOperations.RemoveAll)];
                    case 1: return [2 /*return*/, _a.sent()];
                }
            });
        });
    };
    /**
     * Sets the filters on the current visual to 'filters'.
     *
     * ```javascript
     * visual.setFilters(filters);
     *   .catch(errors => { ... });
     * ```
     *
     * @param {(IFilter[])} filters
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    VisualDescriptor.prototype.setFilters = function (filters) {
        return __awaiter(this, void 0, void 0, function () {
            var response_3;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.page.report.service.hpm.put("/report/pages/".concat(this.page.name, "/visuals/").concat(this.name, "/filters"), filters, { uid: this.page.report.config.uniqueId }, this.page.report.iframe.contentWindow)];
                    case 1: return [2 /*return*/, _a.sent()];
                    case 2:
                        response_3 = _a.sent();
                        throw response_3.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Exports Visual data.
     * Can export up to 30K rows.
     *
     * @param rows: Optional. Default value is 30K, maximum value is 30K as well.
     * @param exportDataType: Optional. Default is ExportDataType.Summarized.
     * ```javascript
     * visual.exportData()
     *  .then(data => { ... });
     * ```
     *
     * @returns {(Promise<IExportDataResult>)}
     */
    VisualDescriptor.prototype.exportData = function (exportDataType, rows) {
        return __awaiter(this, void 0, void 0, function () {
            var exportDataRequestBody, response, response_4;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        exportDataRequestBody = {
                            rows: rows,
                            exportDataType: exportDataType
                        };
                        _a.label = 1;
                    case 1:
                        _a.trys.push([1, 3, , 4]);
                        return [4 /*yield*/, this.page.report.service.hpm.post("/report/pages/".concat(this.page.name, "/visuals/").concat(this.name, "/exportData"), exportDataRequestBody, { uid: this.page.report.config.uniqueId }, this.page.report.iframe.contentWindow)];
                    case 2:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 3:
                        response_4 = _a.sent();
                        throw response_4.body;
                    case 4: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Set slicer state.
     * Works only for visuals of type slicer.
     *
     * @param state: A new state which contains the slicer filters.
     * ```javascript
     * visual.setSlicerState()
     *  .then(() => { ... });
     * ```
     */
    VisualDescriptor.prototype.setSlicerState = function (state) {
        return __awaiter(this, void 0, void 0, function () {
            var response_5;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.page.report.service.hpm.put("/report/pages/".concat(this.page.name, "/visuals/").concat(this.name, "/slicer"), state, { uid: this.page.report.config.uniqueId }, this.page.report.iframe.contentWindow)];
                    case 1: return [2 /*return*/, _a.sent()];
                    case 2:
                        response_5 = _a.sent();
                        throw response_5.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Get slicer state.
     * Works only for visuals of type slicer.
     *
     * ```javascript
     * visual.getSlicerState()
     *  .then(state => { ... });
     * ```
     *
     * @returns {(Promise<ISlicerState>)}
     */
    VisualDescriptor.prototype.getSlicerState = function () {
        return __awaiter(this, void 0, void 0, function () {
            var response, response_6;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.page.report.service.hpm.get("/report/pages/".concat(this.page.name, "/visuals/").concat(this.name, "/slicer"), { uid: this.page.report.config.uniqueId }, this.page.report.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_6 = _a.sent();
                        throw response_6.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Clone existing visual to a new instance.
     *
     * @returns {(Promise<ICloneVisualResponse>)}
     */
    VisualDescriptor.prototype.clone = function (request) {
        if (request === void 0) { request = {}; }
        return __awaiter(this, void 0, void 0, function () {
            var response, response_7;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.page.report.service.hpm.post("/report/pages/".concat(this.page.name, "/visuals/").concat(this.name, "/clone"), request, { uid: this.page.report.config.uniqueId }, this.page.report.iframe.contentWindow)];
                    case 1:
                        response = _a.sent();
                        return [2 /*return*/, response.body];
                    case 2:
                        response_7 = _a.sent();
                        throw response_7.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Sort a visual by dataField and direction.
     *
     * @param request: Sort by visual request.
     *
     * ```javascript
     * visual.sortBy(request)
     *  .then(() => { ... });
     * ```
     */
    VisualDescriptor.prototype.sortBy = function (request) {
        return __awaiter(this, void 0, void 0, function () {
            var response_8;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _a.trys.push([0, 2, , 3]);
                        return [4 /*yield*/, this.page.report.service.hpm.put("/report/pages/".concat(this.page.name, "/visuals/").concat(this.name, "/sortBy"), request, { uid: this.page.report.config.uniqueId }, this.page.report.iframe.contentWindow)];
                    case 1: return [2 /*return*/, _a.sent()];
                    case 2:
                        response_8 = _a.sent();
                        throw response_8.body;
                    case 3: return [2 /*return*/];
                }
            });
        });
    };
    /**
     * Updates the position of a visual.
     *
     * ```javascript
     * visual.moveVisual(x, y, z)
     *   .catch(error => { ... });
     * ```
     *
     * @param {number} x
     * @param {number} y
     * @param {number} z
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    VisualDescriptor.prototype.moveVisual = function (x, y, z) {
        return __awaiter(this, void 0, void 0, function () {
            var pageName, visualName, report;
            return __generator(this, function (_a) {
                pageName = this.page.name;
                visualName = this.name;
                report = this.page.report;
                return [2 /*return*/, report.moveVisual(pageName, visualName, x, y, z)];
            });
        });
    };
    /**
     * Updates the display state of a visual.
     *
     * ```javascript
     * visual.setVisualDisplayState(displayState)
     *   .catch(error => { ... });
     * ```
     *
     * @param {VisualContainerDisplayMode} displayState
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    VisualDescriptor.prototype.setVisualDisplayState = function (displayState) {
        return __awaiter(this, void 0, void 0, function () {
            var pageName, visualName, report;
            return __generator(this, function (_a) {
                pageName = this.page.name;
                visualName = this.name;
                report = this.page.report;
                return [2 /*return*/, report.setVisualDisplayState(pageName, visualName, displayState)];
            });
        });
    };
    /**
     * Resize a visual.
     *
     * ```javascript
     * visual.resizeVisual(width, height)
     *   .catch(error => { ... });
     * ```
     *
     * @param {number} width
     * @param {number} height
     * @returns {Promise<IHttpPostMessageResponse<void>>}
     */
    VisualDescriptor.prototype.resizeVisual = function (width, height) {
        return __awaiter(this, void 0, void 0, function () {
            var pageName, visualName, report;
            return __generator(this, function (_a) {
                pageName = this.page.name;
                visualName = this.name;
                report = this.page.report;
                return [2 /*return*/, report.resizeVisual(pageName, visualName, width, height)];
            });
        });
    };
    return VisualDescriptor;
}());
exports.VisualDescriptor = VisualDescriptor;


/***/ }),

/***/ "./node_modules/window-post-message-proxy/dist/windowPostMessageProxy.js":
/*!*******************************************************************************!*\
  !*** ./node_modules/window-post-message-proxy/dist/windowPostMessageProxy.js ***!
  \*******************************************************************************/
/***/ (function(module) {

/*! window-post-message-proxy v0.2.6 | (c) 2016 Microsoft Corporation MIT */
(function webpackUniversalModuleDefinition(root, factory) {
	if(true)
		module.exports = factory();
	else {}
})(this, function() {
return /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __nested_webpack_require_650__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;
/******/
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __nested_webpack_require_650__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__nested_webpack_require_650__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__nested_webpack_require_650__.c = installedModules;
/******/
/******/ 	// __webpack_public_path__
/******/ 	__nested_webpack_require_650__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __nested_webpack_require_650__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, exports) {

	"use strict";
	var WindowPostMessageProxy = (function () {
	    function WindowPostMessageProxy(options) {
	        var _this = this;
	        if (options === void 0) { options = {
	            processTrackingProperties: {
	                addTrackingProperties: WindowPostMessageProxy.defaultAddTrackingProperties,
	                getTrackingProperties: WindowPostMessageProxy.defaultGetTrackingProperties
	            },
	            isErrorMessage: WindowPostMessageProxy.defaultIsErrorMessage,
	            receiveWindow: window,
	            name: WindowPostMessageProxy.createRandomString()
	        }; }
	        this.pendingRequestPromises = {};
	        // save options with defaults
	        this.addTrackingProperties = (options.processTrackingProperties && options.processTrackingProperties.addTrackingProperties) || WindowPostMessageProxy.defaultAddTrackingProperties;
	        this.getTrackingProperties = (options.processTrackingProperties && options.processTrackingProperties.getTrackingProperties) || WindowPostMessageProxy.defaultGetTrackingProperties;
	        this.isErrorMessage = options.isErrorMessage || WindowPostMessageProxy.defaultIsErrorMessage;
	        this.receiveWindow = options.receiveWindow || window;
	        this.name = options.name || WindowPostMessageProxy.createRandomString();
	        this.logMessages = options.logMessages || false;
	        this.eventSourceOverrideWindow = options.eventSourceOverrideWindow;
	        this.suppressWarnings = options.suppressWarnings || false;
	        if (this.logMessages) {
	            console.log("new WindowPostMessageProxy created with name: " + this.name + " receiving on window: " + this.receiveWindow.document.title);
	        }
	        // Initialize
	        this.handlers = [];
	        this.windowMessageHandler = function (event) { return _this.onMessageReceived(event); };
	        this.start();
	    }
	    // Static
	    WindowPostMessageProxy.defaultAddTrackingProperties = function (message, trackingProperties) {
	        message[WindowPostMessageProxy.messagePropertyName] = trackingProperties;
	        return message;
	    };
	    WindowPostMessageProxy.defaultGetTrackingProperties = function (message) {
	        return message[WindowPostMessageProxy.messagePropertyName];
	    };
	    WindowPostMessageProxy.defaultIsErrorMessage = function (message) {
	        return !!message.error;
	    };
	    /**
	     * Utility to create a deferred object.
	     */
	    // TODO: Look to use RSVP library instead of doing this manually.
	    // From what I searched RSVP would work better because it has .finally and .deferred; however, it doesn't have Typings information. 
	    WindowPostMessageProxy.createDeferred = function () {
	        var deferred = {
	            resolve: null,
	            reject: null,
	            promise: null
	        };
	        var promise = new Promise(function (resolve, reject) {
	            deferred.resolve = resolve;
	            deferred.reject = reject;
	        });
	        deferred.promise = promise;
	        return deferred;
	    };
	    /**
	     * Utility to generate random sequence of characters used as tracking id for promises.
	     */
	    WindowPostMessageProxy.createRandomString = function () {
	        // window.msCrypto for IE
	        var cryptoObj = window.crypto || window.msCrypto;
	        var randomValueArray = new Uint32Array(1);
	        cryptoObj.getRandomValues(randomValueArray);
	        return randomValueArray[0].toString(36).substring(1);
	    };
	    /**
	     * Adds handler.
	     * If the first handler whose test method returns true will handle the message and provide a response.
	     */
	    WindowPostMessageProxy.prototype.addHandler = function (handler) {
	        this.handlers.push(handler);
	    };
	    /**
	     * Removes handler.
	     * The reference must match the original object that was provided when adding the handler.
	     */
	    WindowPostMessageProxy.prototype.removeHandler = function (handler) {
	        var handlerIndex = this.handlers.indexOf(handler);
	        if (handlerIndex === -1) {
	            throw new Error("You attempted to remove a handler but no matching handler was found.");
	        }
	        this.handlers.splice(handlerIndex, 1);
	    };
	    /**
	     * Start listening to message events.
	     */
	    WindowPostMessageProxy.prototype.start = function () {
	        this.receiveWindow.addEventListener('message', this.windowMessageHandler);
	    };
	    /**
	     * Stops listening to message events.
	     */
	    WindowPostMessageProxy.prototype.stop = function () {
	        this.receiveWindow.removeEventListener('message', this.windowMessageHandler);
	    };
	    /**
	     * Post message to target window with tracking properties added and save deferred object referenced by tracking id.
	     */
	    WindowPostMessageProxy.prototype.postMessage = function (targetWindow, message) {
	        // Add tracking properties to indicate message came from this proxy
	        var trackingProperties = { id: WindowPostMessageProxy.createRandomString() };
	        this.addTrackingProperties(message, trackingProperties);
	        if (this.logMessages) {
	            console.log(this.name + " Posting message:");
	            console.log(JSON.stringify(message, null, '  '));
	        }
	        targetWindow.postMessage(message, "*");
	        var deferred = WindowPostMessageProxy.createDeferred();
	        this.pendingRequestPromises[trackingProperties.id] = deferred;
	        return deferred.promise;
	    };
	    /**
	     * Send response message to target window.
	     * Response messages re-use tracking properties from a previous request message.
	     */
	    WindowPostMessageProxy.prototype.sendResponse = function (targetWindow, message, trackingProperties) {
	        this.addTrackingProperties(message, trackingProperties);
	        if (this.logMessages) {
	            console.log(this.name + " Sending response:");
	            console.log(JSON.stringify(message, null, '  '));
	        }
	        targetWindow.postMessage(message, "*");
	    };
	    /**
	     * Message handler.
	     */
	    WindowPostMessageProxy.prototype.onMessageReceived = function (event) {
	        var _this = this;
	        if (this.logMessages) {
	            console.log(this.name + " Received message:");
	            console.log("type: " + event.type);
	            console.log(JSON.stringify(event.data, null, '  '));
	        }
	        var sendingWindow = this.eventSourceOverrideWindow || event.source;
	        var message = event.data;
	        if (typeof message !== "object") {
	            if (!this.suppressWarnings) {
	                console.warn("Proxy(" + this.name + "): Received message that was not an object. Discarding message");
	            }
	            return;
	        }
	        var trackingProperties;
	        try {
	            trackingProperties = this.getTrackingProperties(message);
	        }
	        catch (e) {
	            if (!this.suppressWarnings) {
	                console.warn("Proxy(" + this.name + "): Error occurred when attempting to get tracking properties from incoming message:", JSON.stringify(message, null, '  '), "Error: ", e);
	            }
	        }
	        var deferred;
	        if (trackingProperties) {
	            deferred = this.pendingRequestPromises[trackingProperties.id];
	        }
	        // If message does not have a known ID, treat it as a request
	        // Otherwise, treat message as response
	        if (!deferred) {
	            var handled = this.handlers.some(function (handler) {
	                var canMessageBeHandled = false;
	                try {
	                    canMessageBeHandled = handler.test(message);
	                }
	                catch (e) {
	                    if (!_this.suppressWarnings) {
	                        console.warn("Proxy(" + _this.name + "): Error occurred when handler was testing incoming message:", JSON.stringify(message, null, '  '), "Error: ", e);
	                    }
	                }
	                if (canMessageBeHandled) {
	                    var responseMessagePromise = void 0;
	                    try {
	                        responseMessagePromise = Promise.resolve(handler.handle(message));
	                    }
	                    catch (e) {
	                        if (!_this.suppressWarnings) {
	                            console.warn("Proxy(" + _this.name + "): Error occurred when handler was processing incoming message:", JSON.stringify(message, null, '  '), "Error: ", e);
	                        }
	                        responseMessagePromise = Promise.resolve();
	                    }
	                    responseMessagePromise
	                        .then(function (responseMessage) {
	                        if (!responseMessage) {
	                            var warningMessage = "Handler for message: " + JSON.stringify(message, null, '  ') + " did not return a response message. The default response message will be returned instead.";
	                            if (!_this.suppressWarnings) {
	                                console.warn("Proxy(" + _this.name + "): " + warningMessage);
	                            }
	                            responseMessage = {
	                                warning: warningMessage
	                            };
	                        }
	                        _this.sendResponse(sendingWindow, responseMessage, trackingProperties);
	                    });
	                    return true;
	                }
	            });
	            /**
	             * TODO: Consider returning an error message if nothing handled the message.
	             * In the case of the Report receiving messages all of them should be handled,
	             * however, in the case of the SDK receiving messages it's likely it won't register handlers
	             * for all events. Perhaps make this an option at construction time.
	             */
	            if (!handled && !this.suppressWarnings) {
	                console.warn("Proxy(" + this.name + ") did not handle message. Handlers: " + this.handlers.length + "  Message: " + JSON.stringify(message, null, '') + ".");
	            }
	        }
	        else {
	            /**
	             * If error message reject promise,
	             * Otherwise, resolve promise
	             */
	            var isErrorMessage = true;
	            try {
	                isErrorMessage = this.isErrorMessage(message);
	            }
	            catch (e) {
	                console.warn("Proxy(" + this.name + ") Error occurred when trying to determine if message is consider an error response. Message: ", JSON.stringify(message, null, ''), 'Error: ', e);
	            }
	            if (isErrorMessage) {
	                deferred.reject(message);
	            }
	            else {
	                deferred.resolve(message);
	            }
	            // TODO: Move to .finally clause up where promise is created for better maitenance like original proxy code.
	            delete this.pendingRequestPromises[trackingProperties.id];
	        }
	    };
	    WindowPostMessageProxy.messagePropertyName = "windowPostMessageProxy";
	    return WindowPostMessageProxy;
	}());
	exports.WindowPostMessageProxy = WindowPostMessageProxy;


/***/ })
/******/ ])
});
;
//# sourceMappingURL=windowPostMessageProxy.js.map

/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
var __webpack_exports__ = {};
// This entry need to be wrapped in an IIFE because it need to be isolated against other modules in the chunk.
(() => {
var exports = __webpack_exports__;
/*!*******************************!*\
  !*** ./src/powerbi-client.ts ***!
  \*******************************/
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.RelativeTimeFilterBuilder = exports.RelativeDateFilterBuilder = exports.TopNFilterBuilder = exports.AdvancedFilterBuilder = exports.BasicFilterBuilder = exports.QuickCreate = exports.VisualDescriptor = exports.Visual = exports.Qna = exports.Page = exports.Embed = exports.Tile = exports.Dashboard = exports.Report = exports.models = exports.factories = exports.service = void 0;
/**
 * @hidden
 */
var models = __webpack_require__(/*! powerbi-models */ "./node_modules/powerbi-models/dist/models.js");
exports.models = models;
var service = __webpack_require__(/*! ./service */ "./src/service.ts");
exports.service = service;
var factories = __webpack_require__(/*! ./factories */ "./src/factories.ts");
exports.factories = factories;
var report_1 = __webpack_require__(/*! ./report */ "./src/report.ts");
Object.defineProperty(exports, "Report", ({ enumerable: true, get: function () { return report_1.Report; } }));
var dashboard_1 = __webpack_require__(/*! ./dashboard */ "./src/dashboard.ts");
Object.defineProperty(exports, "Dashboard", ({ enumerable: true, get: function () { return dashboard_1.Dashboard; } }));
var tile_1 = __webpack_require__(/*! ./tile */ "./src/tile.ts");
Object.defineProperty(exports, "Tile", ({ enumerable: true, get: function () { return tile_1.Tile; } }));
var embed_1 = __webpack_require__(/*! ./embed */ "./src/embed.ts");
Object.defineProperty(exports, "Embed", ({ enumerable: true, get: function () { return embed_1.Embed; } }));
var page_1 = __webpack_require__(/*! ./page */ "./src/page.ts");
Object.defineProperty(exports, "Page", ({ enumerable: true, get: function () { return page_1.Page; } }));
var qna_1 = __webpack_require__(/*! ./qna */ "./src/qna.ts");
Object.defineProperty(exports, "Qna", ({ enumerable: true, get: function () { return qna_1.Qna; } }));
var visual_1 = __webpack_require__(/*! ./visual */ "./src/visual.ts");
Object.defineProperty(exports, "Visual", ({ enumerable: true, get: function () { return visual_1.Visual; } }));
var visualDescriptor_1 = __webpack_require__(/*! ./visualDescriptor */ "./src/visualDescriptor.ts");
Object.defineProperty(exports, "VisualDescriptor", ({ enumerable: true, get: function () { return visualDescriptor_1.VisualDescriptor; } }));
var quickCreate_1 = __webpack_require__(/*! ./quickCreate */ "./src/quickCreate.ts");
Object.defineProperty(exports, "QuickCreate", ({ enumerable: true, get: function () { return quickCreate_1.QuickCreate; } }));
var FilterBuilders_1 = __webpack_require__(/*! ./FilterBuilders */ "./src/FilterBuilders/index.ts");
Object.defineProperty(exports, "BasicFilterBuilder", ({ enumerable: true, get: function () { return FilterBuilders_1.BasicFilterBuilder; } }));
Object.defineProperty(exports, "AdvancedFilterBuilder", ({ enumerable: true, get: function () { return FilterBuilders_1.AdvancedFilterBuilder; } }));
Object.defineProperty(exports, "TopNFilterBuilder", ({ enumerable: true, get: function () { return FilterBuilders_1.TopNFilterBuilder; } }));
Object.defineProperty(exports, "RelativeDateFilterBuilder", ({ enumerable: true, get: function () { return FilterBuilders_1.RelativeDateFilterBuilder; } }));
Object.defineProperty(exports, "RelativeTimeFilterBuilder", ({ enumerable: true, get: function () { return FilterBuilders_1.RelativeTimeFilterBuilder; } }));
/**
 * Makes Power BI available to the global object for use in applications that don't have module loading support.
 *
 * Note: create an instance of the class with the default configuration for normal usage, or save the class so that you can create an instance of the service.
 */
var powerbi = new service.Service(factories.hpmFactory, factories.wpmpFactory, factories.routerFactory);
// powerBI SDK may use Power BI object under different key, in order to avoid name collisions
if (window.powerbi && window.powerBISDKGlobalServiceInstanceName) {
    window[window.powerBISDKGlobalServiceInstanceName] = powerbi;
}
else {
    // Default to Power BI.
    window.powerbi = powerbi;
}

})();

/******/ 	return __webpack_exports__;
/******/ })()
;
});
//# sourceMappingURL=powerbi.js.map