page 9633 "Page Inspection Extensions"
{
    Caption = 'Page Inspection Extensions';
    PageType = ListPart;
    SourceTable = "NAV App Installed App";
    SourceTableView = WHERE(Name = FILTER(<> '_Exclude_*'));
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Visible = IsExtensionListVisible;
                field("App ID"; Rec."App ID")
                {
                    ApplicationArea = All;
                    Caption = 'App ID';
                    ShowCaption = false;
                    ToolTip = 'Specifies the ID of the extension.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    DrillDown = true;
                    ShowCaption = false;
                    ToolTip = 'Specifies the name of the extension.';
                }
                field(Version; Version)
                {
                    ApplicationArea = All;
                    Caption = 'Version';
                    ShowCaption = false;
                    ToolTip = 'Specifies the version of extension.';
                }
                field(PublishedBy; PublishedBy)
                {
                    ApplicationArea = All;
                    Caption = 'Published by';
                    ShowCaption = false;
                    ToolTip = 'Specifies who published the extension.';
                }
                field(TypeOfExtension; TypeOfExtension)
                {
                    ApplicationArea = All;
                    Caption = 'Extension execution info and type.';
                    ShowCaption = false;
                    ToolTip = 'Specifies extension execution information and extension type.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ExtensionExecutionInfo: Record "Extension Execution Info";
        ExtensionType: Text;
        ExtensionInfo: Text;
        SeparatorText: Text;
    begin
        Version := StrSubstNo('%1.%2.%3', "Version Major", "Version Minor", "Version Build");
        PublishedBy := StrSubstNo('by %1', Publisher);

        ExtensionType := '';
        ExtensionInfo := '';

        if AllObjWithCaption.ReadPermission() then begin
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("App Package ID", "Package ID");

            // page added by extension
            AllObjWithCaption.SetRange("Object ID", CurrentPageId);
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
            if AllObjWithCaption.FindFirst() then
                ExtensionType := ExtensionType + ', ' + NewPageLbl;

            // table added by extension
            AllObjWithCaption.SetRange("Object ID", CurrentTableId);
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            if AllObjWithCaption.FindFirst() then
                ExtensionType := ExtensionType + ', ' + NewTableLbl;

            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("App Package ID", "Package ID");

            // page extended by extension
            AllObjWithCaption.SetRange("Object Subtype", StrSubstNo('%1', CurrentPageId));
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::PageExtension);
            if AllObjWithCaption.FindFirst() then
                ExtensionType := ExtensionType + ', ' + ExtPageLbl;

            // table extended by extension
            AllObjWithCaption.SetRange("Object Subtype", StrSubstNo('%1', CurrentTableId));
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::TableExtension);
            if AllObjWithCaption.FindFirst() then
                ExtensionType := ExtensionType + ', ' + ExtTableLbl;

            ExtensionType := DelChr(ExtensionType, '<', ',');
        end;

        if AllObjWithCaption.ReadPermission() then begin
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("App Package ID", Rec."Package ID");

            if AllObjWithCaption.FindFirst() then begin
                ExtensionExecutionInfo.Reset();
                ExtensionExecutionInfo.SetRange("Form ID", CurrentFormId);
                ExtensionExecutionInfo.SetRange("Runtime Package ID", AllObjWithCaption."App Runtime Package ID");

                if ExtensionExecutionInfo.FindFirst() then
                    ExtensionInfo := StrSubstNo(
                        MillisecondsAndSubscribersLbl,
                        Format(ExtensionExecutionInfo."Execution Time"),
                        Format(ExtensionExecutionInfo."Subscriber Execution Count"))
                else
                    ExtensionInfo := NoExtensionInfoLbl;
            end;
        end;


        if (StrLen(ExtensionType) > 0) and (StrLen(ExtensionInfo) > 0) then
            SeparatorText := '; '
        else
            SeparatorText := '';

        TypeOfExtension := StrSubstNo(TypeOfExtensionFmtLbl, ExtensionInfo, SeparatorText, ExtensionType);
    end;

    var
        Version: Text;
        PublishedBy: Text;
        IsExtensionListVisible: Boolean;
        TypeOfExtension: Text;
        CurrentFormId: Guid;
        CurrentPageId: Integer;
        CurrentTableId: Integer;
        FilterConditions: Text;
        NewPageLbl: Label 'Adds page';
        NewTableLbl: Label 'Adds table';
        ExtPageLbl: Label 'Extends page';
        ExtTableLbl: Label 'Extends table';
        MillisecondsAndSubscribersLbl: Label '%1ms, %2 subs.', Comment = '%1 is millisceonds, %2 is subscribers. "subs." is an abbreviation of "subscribers"';
        NoExtensionInfoLbl: Label 'No extension info';
        TypeOfExtensionFmtLbl: Label '%1%2%3', Locked = true;
        OrFilterFmtLbl: Label '%1|', Locked = true;

    [Scope('OnPrem')]
    procedure FilterForExtAffectingPage(PageId: Integer; TableId: Integer; FormId: Guid)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ExtensionExecutionInfo: Record "Extension Execution Info";
        TempGuid: Guid;
    begin
        if (PageId = CurrentPageId) and (TableId = CurrentTableId) then
            exit;

        CurrentPageId := PageId;
        CurrentTableId := TableId;
        FilterConditions := '';

        CurrentFormId := FormId;

        if AllObjWithCaption.ReadPermission() then begin
            // check if this page was added by extension
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
            AllObjWithCaption.SetRange("Object ID", PageId);
            if AllObjWithCaption.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo('%1|', AllObjWithCaption."App Package ID");
                until AllObjWithCaption.Next() = 0;

            // check if page was extended
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::PageExtension);
            AllObjWithCaption.SetRange("Object Subtype", StrSubstNo('%1', PageId));
            if AllObjWithCaption.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo('%1|', AllObjWithCaption."App Package ID");
                until AllObjWithCaption.Next() = 0;

            // check if source table was added by extension
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            AllObjWithCaption.SetRange("Object ID", TableId);
            if AllObjWithCaption.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo('%1|', AllObjWithCaption."App Package ID");
                until AllObjWithCaption.Next() = 0;

            // check if source table was extended by extension
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::TableExtension);
            AllObjWithCaption.SetRange("Object Subtype", StrSubstNo('%1', TableId));
            if AllObjWithCaption.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo('%1|', AllObjWithCaption."App Package ID");
                until AllObjWithCaption.Next() = 0;

            // Add filters for arbitrary code which has executed on the form
            if ExtensionExecutionInfo.ReadPermission() then begin
                ExtensionExecutionInfo.SetRange("Form ID", CurrentFormId);
                if ExtensionExecutionInfo.Find('-') then
                    repeat
                        AllObjWithCaption.Reset();
                        AllObjWithCaption.SetRange("App Runtime Package ID", ExtensionExecutionInfo."Runtime Package ID");
                        if AllObjWithCaption.FindFirst() then
                            FilterConditions := FilterConditions + StrSubstNo(OrFilterFmtLbl, AllObjWithCaption."App Package ID");
                    until ExtensionExecutionInfo.Next() = 0;
            end;
        end;

        Reset();
        if FilterConditions <> '' then begin
            FilterConditions := DelChr(FilterConditions, '>', '|');
            SetFilter("Package ID", FilterConditions);
        end else begin
            TempGuid := CreateGuid();
            Clear(TempGuid);
            SetFilter("Package ID", '%1', TempGuid);
        end;

        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure SetExtensionListVisibility(NewVisibilityValue: Boolean)
    begin
        IsExtensionListVisible := NewVisibilityValue;
    end;
}