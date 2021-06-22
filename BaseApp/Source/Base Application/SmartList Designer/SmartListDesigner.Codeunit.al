/// <summary>
/// Contains methods for interacting with/opening the SmartList Designer 
/// </summary>
codeunit 888 "SmartList Designer"
{
    Access = Public;

    /// <summary>
    /// Check if the provided user has been granted access to the
    /// SmartList Designer API
    /// </summary>
    /// <returns>True if provided user has access to the API; Otherwise false.</returns>
    procedure DoesUserHaveAPIAccess(UserSID: Guid): Boolean
    var
        SmartListDesignerImpl: Codeunit "SmartList Designer Impl";
    begin
        exit(SmartListDesignerImpl.DoesUserHaveAPIAccess(UserSID));
    end;

    /// <summary>
    /// Opens up the SmartList Designer to create a new SmartList
    /// </summary>
    procedure RunForNew()
    var
        SmartListDesignerImpl: Codeunit "SmartList Designer Impl";
    begin
        SmartListDesignerImpl.RunForNew();
    end;

    /// <summary>
    /// Opens up the SmartList Designer to edit an existing SmartList
    /// </summary>
    /// <param name="QueryId">The ID of the existing SmartList query to edit.</param>
    procedure RunForQuery(QueryId: Guid)
    var
        SmartListDesignerImpl: Codeunit "SmartList Designer Impl";
    begin
        SmartListDesignerImpl.RunForQuery(QueryId);
    end;

    /// <summary>
    /// Opens up the SmartList Designer to create a new SmartList using
    /// the provided table as a starting point.
    /// </summary>
    /// <param name="TableNo">The ID of a table to start creating a SmartList query over.</param>
    procedure RunForTable(TableNo: Integer)
    begin
        RunForTableAndView(TableNo, '');
    end;

    /// <summary>
    /// Opens up the SmartList Designer to create a new SmartList based
    /// on a selected table.
    /// </summary>
    /// <param name="TableNo">The ID of the table to use as the basis for a SmartList query.</param>
    /// <param name="ViewId">The optional view ID token that contains information about the page or view that the user was using before they opened SmartList Designer.</param>
    procedure RunForTableAndView(TableNo: Integer; ViewId: Text)
    var
        SmartListDesignerImpl: Codeunit "SmartList Designer Impl";
    begin
        SmartListDesignerImpl.RunForTable(TableNo, ViewId);
    end;

    /// <summary>
    /// Indicates if the SmartList designer functionality is enabled.
    /// </summary>
    /// <returns>True if the designer is enabled; Otherwise false.</returns>
    procedure IsEnabled(): Boolean
    var
        SmartListDesignerImpl: Codeunit "SmartList Designer Impl";
    begin
        exit(SmartListDesignerImpl.IsDesignerEnabled());
    end;
}