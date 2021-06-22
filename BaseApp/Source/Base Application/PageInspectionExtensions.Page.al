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
                    Caption = 'Type of extension.';
                    ShowCaption = false;
                    ToolTip = 'Specifies extension type.';
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
    begin
        Version := StrSubstNo('%1.%2.%3', "Version Major", "Version Minor", "Version Build");
        PublishedBy := StrSubstNo('by %1', Publisher);

        TypeOfExtension := '';

        if ApplicationObjectMetadata.ReadPermission then begin
            ApplicationObjectMetadata.Reset();
            ApplicationObjectMetadata.SetFilter("Package ID", '%1', "Package ID");

            // page added by extension
            ApplicationObjectMetadata.SetFilter("Object ID", '%1', CurrentPageId);
            ApplicationObjectMetadata.SetFilter("Object Type", '%1', ApplicationObjectMetadata."Object Type"::Page);
            if ApplicationObjectMetadata.FindFirst then
                TypeOfExtension := TypeOfExtension + ', ' + NewPageLbl;

            // table added by extension
            ApplicationObjectMetadata.SetFilter("Object ID", '%1', CurrentTableId);
            ApplicationObjectMetadata.SetFilter("Object Type", '%1', ApplicationObjectMetadata."Object Type"::Table);
            if ApplicationObjectMetadata.FindFirst then
                TypeOfExtension := TypeOfExtension + ', ' + NewTableLbl;

            ApplicationObjectMetadata.Reset();
            ApplicationObjectMetadata.SetFilter("Package ID", '%1', "Package ID");

            // page extended by extension
            ApplicationObjectMetadata.SetFilter("Object Subtype", '%1', StrSubstNo('%1', CurrentPageId));
            ApplicationObjectMetadata.SetFilter("Object Type", '%1', ApplicationObjectMetadata."Object Type"::PageExtension);
            if ApplicationObjectMetadata.FindFirst then
                TypeOfExtension := TypeOfExtension + ', ' + ExtPageLbl;

            // table extended by extension
            ApplicationObjectMetadata.SetFilter("Object Subtype", '%1', StrSubstNo('%1', CurrentTableId));
            ApplicationObjectMetadata.SetFilter("Object Type", '%1', ApplicationObjectMetadata."Object Type"::TableExtension);
            if ApplicationObjectMetadata.FindFirst then
                TypeOfExtension := TypeOfExtension + ', ' + ExtTableLbl;

            TypeOfExtension := DelChr(TypeOfExtension, '<', ',');
        end;
    end;

    var
        Version: Text;
        PublishedBy: Text;
        IsExtensionListVisible: Boolean;
        TypeOfExtension: Text;
        CurrentPageId: Integer;
        CurrentTableId: Integer;
        FilterConditions: Text;
        NewPageLbl: Label 'Adds page';
        NewTableLbl: Label 'Adds table';
        ExtPageLbl: Label 'Extends page';
        ExtTableLbl: Label 'Extends table';

    [Scope('OnPrem')]
    procedure FilterForExtAffectingPage(PageId: Integer; TableId: Integer)
    var
        ApplicationObjectMetadata: Record "Application Object Metadata";
        TempGuid: Guid;
    begin
        CurrentPageId := PageId;
        CurrentTableId := TableId;
        FilterConditions := '';

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

        Reset;
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
    procedure SetExtensionListVisbility(NewVisibilityValue: Boolean)
    begin
        IsExtensionListVisible := NewVisibilityValue;
    end;
}

