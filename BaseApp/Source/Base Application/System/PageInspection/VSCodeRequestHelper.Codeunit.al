namespace System.Tooling;

using System.Apps;
using System.Reflection;
using System.Utilities;

codeunit 5378 "VS Code Request Helper"
{
    Access = Internal;

    var
        AllObjWithCaption: Record AllObjWithCaption;
        UriBuilder: Codeunit "Uri Builder";
        VSCodeRequestHelper: DotNet VSCodeRequestHelper;
        AlExtensionUriTxt: Label 'vscode://ms-dynamics-smb.al', Locked = true;
        BaseApplicationIdTxt: Label '437dbf0e-84ff-417a-965d-ed2bb9650972', Locked = true;
        SystemApplicationIdTxt: Label '63ca2fa4-4f03-4f2b-a480-172fef340d3f', Locked = true;
        ApplicationIdTxt: Label 'c1335042-3002-4257-bf8a-75c898ccb1b8', Locked = true;
        FilterConditions: Text;

    [Scope('OnPrem')]
    local procedure GetUrlToNavigateInVSCode(ObjectType: Option; ObjectId: Integer; ObjectName: Text; ControlName: Text; PageInfoAndFields: Record "Page Info And Fields"): Text
    var
        Url: Text;
    begin
        UriBuilder.Init(AlExtensionUriTxt + '/navigateTo');

        UriBuilder.AddQueryParameter('type', FormatObjectType(ObjectType));
        UriBuilder.AddQueryParameter('id', Format(ObjectId));
        UriBuilder.AddQueryParameter('name', ObjectName);
        UriBuilder.AddQueryParameter('appid', GetAppIdForObject(ObjectType, ObjectId));
        if Text.StrLen(ControlName) <> 0 then
            UriBuilder.AddQueryParameter('fieldName', Format(PageInfoAndFields."Field Name"));
        UriBuilder.SetQuery(UriBuilder.GetQuery() + '&' + VSCodeRequestHelper.GetLaunchInformationQueryPart());
        UriBuilder.AddQueryParameter('sessionId', Format(SessionId()));
        UriBuilder.AddQueryParameter('dependencies', GetDependencies(PageInfoAndFields."Page ID", PageInfoAndFields."Source Table No.", PageInfoAndFields."Current Form ID"));

        Url := GetAbsoluteUri();
        if DoesExceedCharLimit(Url) then
            // If the URL length exceeds 2000 characters then it will crash the page, so we truncate it.
            exit(AlExtensionUriTxt + '/truncated');

        exit(Url);
    end;

    [Scope('OnPrem')]
    procedure GetUrlToNavigatePageInVSCode(PageInfoAndFields: Record "Page Info And Fields"): Text
    begin
        exit(GetUrlToNavigateInVSCode(AllObjWithCaption."Object Type"::Page, PageInfoAndFields."Page ID", PageInfoAndFields."Page Name", '', PageInfoAndFields));
    end;

    [Scope('OnPrem')]
    procedure GetUrlToNavigateFieldInVSCode(PageInfoAndFields: Record "Page Info And Fields"): Text
    begin
        exit(GetUrlToNavigateInVSCode(AllObjWithCaption."Object Type"::Table, PageInfoAndFields."Source Table No.", PageInfoAndFields."Source Table Name", PageInfoAndFields."Field Name", PageInfoAndFields));
    end;

    [Scope('OnPrem')]
    local procedure GetAppIdForObject(ObjectType: Option; ObjectId: Integer): Text
    var
        NavAppInstalledApp: Record "NAV App Installed App";
    begin
        if AllObjWithCaption.ReadPermission() then begin
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", ObjectType);
            AllObjWithCaption.SetRange("Object ID", ObjectId);

            if AllObjWithCaption.FindFirst() then begin
                NavAppInstalledApp.Reset();
                NavAppInstalledApp.SetRange("Package ID", AllObjWithCaption."App Runtime Package ID");
                if NavAppInstalledApp.FindFirst() then
                    exit(NavAppInstalledApp."App ID");
            end;
        end;
    end;

    [Scope('OnPrem')]
    local procedure GetDependencies(PageId: Integer; TableId: Integer; FormId: Guid): Text
    var
        NavAppInstalledApp: Record "NAV App Installed App";
        DependencyList: TextBuilder;
    begin
        FilterForExtAffectingPage(PageId, TableId, FormId, NavAppInstalledApp);

        if NavAppInstalledApp.FindFirst() then
            repeat
                DependencyList.Append(FormatDependency(NavAppInstalledApp));
            until NavAppInstalledApp.Next() = 0;

        if DoesExceedCharLimit(GetAbsoluteUri() + DependencyList.ToText()) then
            exit('truncated');

        exit(DependencyList.ToText());
    end;

    [Scope('OnPrem')]
    local procedure FormatDependency(NavAppInstalledApp: Record "NAV App Installed App"): Text
    var
        AppVersion: Text;
        AppVersionLbl: Label '%1.%2.%3.%4', Comment = '%1 = major, %2 = minor, %3 = build, %4 = revision', Locked = true;
        DependencyFormatLbl: Label '%1,%2,%3,%4;', Comment = '%1 = Id, %2 = Name, %3 = Publisher, %4 = Version', Locked = true;
    begin
        // Skip System and Base app
        case NavAppInstalledApp."App ID" of
            SystemApplicationIdTxt, BaseApplicationIdTxt, ApplicationIdTxt:
                exit('')
            else
                AppVersion := StrSubstNo(AppVersionLbl, NavAppInstalledApp."Version Major", NavAppInstalledApp."Version Minor", NavAppInstalledApp."Version Build", NavAppInstalledApp."Version Revision");
                exit(StrSubstNo(DependencyFormatLbl, Format(NavAppInstalledApp."App ID", 0, 4), NavAppInstalledApp.Name, NavAppInstalledApp.Publisher, AppVersion));
        end;
    end;

    [Scope('OnPrem')]
    local procedure FormatObjectType(ObjectType: Option): Text
    begin
        case ObjectType of
            AllObjWithCaption."Object Type"::Page:
                exit('page');
            AllObjWithCaption."Object Type"::table:
                exit('table');
            else
                Error('ObjectType not supported');
        end;
    end;

    [Scope('OnPrem')]
    procedure FilterForExtAffectingPage(PageId: Integer; TableId: Integer; FormId: Guid; var NAVAppInstalledApp: Record "NAV App Installed App")
    var
        ExtensionExecutionInfo: Record "Extension Execution Info";
        TempGuid: Guid;
        OrFilterFmtLbl: Label '%1|', Locked = true;
    begin
        if AllObjWithCaption.ReadPermission() then begin
            // check if this page was added by extension
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
            AllObjWithCaption.SetRange("Object ID", PageId);
            if AllObjWithCaption.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo(OrFilterFmtLbl, AllObjWithCaption."App Package ID");
                until AllObjWithCaption.Next() = 0;

            // check if page was extended
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::PageExtension);
            AllObjWithCaption.SetRange("Object Subtype", Format(PageId));
            if AllObjWithCaption.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo(OrFilterFmtLbl, AllObjWithCaption."App Package ID");
                until AllObjWithCaption.Next() = 0;

            // check if source table was added by extension
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            AllObjWithCaption.SetRange("Object ID", TableId);
            if AllObjWithCaption.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo(OrFilterFmtLbl, AllObjWithCaption."App Package ID");
                until AllObjWithCaption.Next() = 0;

            // check if source table was extended by extension
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::TableExtension);
            AllObjWithCaption.SetRange("Object Subtype", Format(TableId));
            if AllObjWithCaption.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo(OrFilterFmtLbl, AllObjWithCaption."App Package ID");
                until AllObjWithCaption.Next() = 0;

            // Add filters for arbitrary code which has executed on the form
            if ExtensionExecutionInfo.ReadPermission() then begin
                ExtensionExecutionInfo.SetRange("Form ID", FormId);
                if ExtensionExecutionInfo.Find('-') then
                    repeat
                        AllObjWithCaption.Reset();
                        AllObjWithCaption.SetRange("App Runtime Package ID", ExtensionExecutionInfo."Runtime Package ID");
                        if AllObjWithCaption.FindFirst() then
                            FilterConditions := FilterConditions + StrSubstNo(OrFilterFmtLbl, AllObjWithCaption."App Package ID");
                    until ExtensionExecutionInfo.Next() = 0;
            end;
        end;

        NAVAppInstalledApp.Reset();
        if FilterConditions <> '' then begin
            FilterConditions := DelChr(FilterConditions, '>', '|');
            NAVAppInstalledApp.SetFilter(NAVAppInstalledApp."Package ID", FilterConditions);
        end else begin
            TempGuid := CreateGuid();
            Clear(TempGuid);
            NAVAppInstalledApp.SetFilter(NAVAppInstalledApp."Package ID", '%1', TempGuid);
        end;
    end;

    [Scope('OnPrem')]
    local procedure GetAbsoluteUri(): Text
    var
        Uri: Codeunit Uri;
    begin
        UriBuilder.GetUri(Uri);
        exit(Uri.GetAbsoluteUri());
    end;

    [Scope('OnPrem')]
    local procedure DoesExceedCharLimit(Url: Text): Boolean
    begin
        exit(StrLen(Url) > 2000);
    end;
}