page 9633 "Page Inspection Extensions"
{
    Caption = 'Page Inspection Extensions';
    PageType = ListPart;
    SourceTable = "NAV App Installed App";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Visible = IsExtensionListVisible;
                field("Package ID"; "Package ID")
                {
                    ApplicationArea = All;
                    Caption = 'Package ID';
                    ShowCaption = false;
                    ToolTip = 'Specifies the ID of the package.';
                }
                field(Name; Name)
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
        ApplicationObjectMetadata: Record "Application Object Metadata";
        ExtensionExecutionInfo: Record "Extension Execution Info";
        ExtensionType: Text;
        ExtensionInfo: Text;
        SeparatorText: Text;
    begin
        Version := StrSubstNo('%1.%2.%3', "Version Major", "Version Minor", "Version Build");
        PublishedBy := StrSubstNo('by %1', Publisher);

        ExtensionType := '';
        ExtensionInfo := '';

        if ApplicationObjectMetadata.ReadPermission then begin
            ApplicationObjectMetadata.Reset();
            ApplicationObjectMetadata.SetFilter("Package ID", '%1', "Package ID");

            // page added by extension
            ApplicationObjectMetadata.SetFilter("Object ID", '%1', CurrentPageId);
            ApplicationObjectMetadata.SetFilter("Object Type", '%1', ApplicationObjectMetadata."Object Type"::Page);
            if ApplicationObjectMetadata.FindFirst then
                ExtensionType := ExtensionType + ', ' + NewPageLbl;

            // table added by extension
            ApplicationObjectMetadata.SetFilter("Object ID", '%1', CurrentTableId);
            ApplicationObjectMetadata.SetFilter("Object Type", '%1', ApplicationObjectMetadata."Object Type"::Table);
            if ApplicationObjectMetadata.FindFirst then
                ExtensionType := ExtensionType + ', ' + NewTableLbl;

            ApplicationObjectMetadata.Reset();
            ApplicationObjectMetadata.SetFilter("Package ID", '%1', "Package ID");

            // page extended by extension
            ApplicationObjectMetadata.SetFilter("Object Subtype", '%1', StrSubstNo('%1', CurrentPageId));
            ApplicationObjectMetadata.SetFilter("Object Type", '%1', ApplicationObjectMetadata."Object Type"::PageExtension);
            if ApplicationObjectMetadata.FindFirst then
                ExtensionType := ExtensionType + ', ' + ExtPageLbl;

            // table extended by extension
            ApplicationObjectMetadata.SetFilter("Object Subtype", '%1', StrSubstNo('%1', CurrentTableId));
            ApplicationObjectMetadata.SetFilter("Object Type", '%1', ApplicationObjectMetadata."Object Type"::TableExtension);
            if ApplicationObjectMetadata.FindFirst then
                ExtensionType := ExtensionType + ', ' + ExtTableLbl;

            ExtensionType := DelChr(ExtensionType, '<', ',');
        end;

        if ApplicationObjectMetadata.ReadPermission then begin
            ApplicationObjectMetadata.Reset();
            ApplicationObjectMetadata.SetFilter("Package ID", '%1', Rec."Package ID");

            if ApplicationObjectMetadata.FindFirst() then begin
                ExtensionExecutionInfo.Reset();
                ExtensionExecutionInfo.SetFilter("Form ID", '%1', CurrentFormId);
                ExtensionExecutionInfo.SetFilter("Runtime Package ID", '%1', ApplicationObjectMetadata."Runtime Package ID");

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
        ApplicationObjectMetadata: Record "Application Object Metadata";
        ExtensionExecutionInfo: Record "Extension Execution Info";
        TempGuid: Guid;
    begin
        if (PageId = CurrentPageId) and (TableId = CurrentTableId) then
            exit;

        CurrentPageId := PageId;
        CurrentTableId := TableId;
        FilterConditions := '';

        CurrentFormId := FormId;

        if ApplicationObjectMetadata.ReadPermission then begin
            // check if this page was added by extension
            ApplicationObjectMetadata.Reset();
            ApplicationObjectMetadata.SetFilter("Object Type", '%1', ApplicationObjectMetadata."Object Type"::Page);
            ApplicationObjectMetadata.SetFilter("Object ID", '%1', PageId);
            if ApplicationObjectMetadata.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo('%1|', ApplicationObjectMetadata."Package ID");
                until ApplicationObjectMetadata.Next = 0;

            // check if page was extended
            ApplicationObjectMetadata.Reset();
            ApplicationObjectMetadata.SetFilter("Object Type", '%1', ApplicationObjectMetadata."Object Type"::PageExtension);
            ApplicationObjectMetadata.SetFilter("Object Subtype", '%1', StrSubstNo('%1', PageId));
            if ApplicationObjectMetadata.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo('%1|', ApplicationObjectMetadata."Package ID");
                until ApplicationObjectMetadata.Next = 0;

            // check if source table was added by extension
            ApplicationObjectMetadata.Reset();
            ApplicationObjectMetadata.SetFilter("Object Type", '%1', ApplicationObjectMetadata."Object Type"::Table);
            ApplicationObjectMetadata.SetFilter("Object ID", '%1', TableId);
            if ApplicationObjectMetadata.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo('%1|', ApplicationObjectMetadata."Package ID");
                until ApplicationObjectMetadata.Next = 0;

            // check if source table was extended by extension
            ApplicationObjectMetadata.Reset();
            ApplicationObjectMetadata.SetFilter("Object Type", '%1', ApplicationObjectMetadata."Object Type"::TableExtension);
            ApplicationObjectMetadata.SetFilter("Object Subtype", '%1', StrSubstNo('%1', TableId));
            if ApplicationObjectMetadata.Find('-') then
                repeat
                    FilterConditions := FilterConditions + StrSubstNo('%1|', ApplicationObjectMetadata."Package ID");
                until ApplicationObjectMetadata.Next = 0;
        end;

        // Add filters for arbitrary code which has executed on the form
        if ExtensionExecutionInfo.ReadPermission then begin
            ExtensionExecutionInfo.SetFilter("Form ID", '%1', CurrentFormId);
            if ExtensionExecutionInfo.Find('-') then
                repeat
                    ApplicationObjectMetadata.Reset();
                    ApplicationObjectMetadata.SetFilter("Runtime Package ID", '%1', ExtensionExecutionInfo."Runtime Package ID");
                    if ApplicationObjectMetadata.FindFirst() then
                        FilterConditions := FilterConditions + StrSubstNo(OrFilterFmtLbl, ApplicationObjectMetadata."Package ID");
                until ExtensionExecutionInfo.Next() = 0;
        end;

        Reset();
        if FilterConditions <> '' then begin
            FilterConditions := DelChr(FilterConditions, '>', '|');
            SetFilter("Package ID", FilterConditions);
        end else begin
            TempGuid := CreateGuid;
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