namespace System.Tooling;

using System.Reflection;

page 9640 "Column Picker"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    SourceTable = "Page Table Field";
    Caption = 'Insert column(s)';
    DataCaptionExpression = '';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = true;
    ShowFilter = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            field(SourceTable; SourceTableInfo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Source table';
                Editable = false;
                ToolTip = 'Specifies source table name and id.';
            }
            field(SourcePage; SourcePageInfo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show available fields from';
                Editable = true;
                ToolTip = 'Specifies source page name, id, and type.';
                Visible = AreTherePagesAvailable;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    if PAGE.RunModal(Page::"List and Card page picker", PageMetadata) = ACTION::LookupOK then begin
                        SourcePageId := PageMetadata.Id;
                        SourcePageName := PageMetadata.Name;
                        Text := StrSubstNo('%1 (%2, %3)', PageMetadata.Name, PageMetadata.Id, PageMetadata.PageType);
                        exit(true);
                    end;
                    exit(false);
                end;

                trigger OnValidate()
                begin
                    Rec.SetFilter("Page ID", '%1', SourcePageId);
                    CurrPage.Update();
                end;
            }
            field(Warning; UsingTableAsSourceMsg)
            {
                Visible = not AreTherePagesAvailable;
                ShowCaption = false;
                Style = Attention;
                ApplicationArea = All;
                Editable = false;
                Importance = Promoted;
            }
            repeater(GroupName)
            {
                field("Field ID"; Rec."Table Field Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the table field id.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the field name.';
                }
                field(Example; Example)
                {
                    ApplicationArea = All;
                    Caption = 'Example';
                    Editable = false;
                    Style = AttentionAccent;
                    ToolTip = 'Specifies an example value for the table field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description for the field.';
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        // Fill in the source table information
        SourceTableId := Rec."Table No";
        PageTableFieldRecRef.Open(SourceTableId);
        SourceTableName := PageTableFieldRecRef.Name();
        SourceTableInfo := StrSubstNo('%1 (%2)', SourceTableName, SourceTableId);
        IsTableIsEmpty := PageTableFieldRecRef.IsEmpty();

        // Filter the fields shown in the repeater control
        FilterSourcePages();
    end;

    trigger OnAfterGetRecord()
    begin
        if not IsTableIsEmpty then
            Example := GetExample(Rec."Table Field Id");
    end;

    local procedure FilterSourcePages()
    begin
        PageMetadata.SetFilter(SourceTable, '%1', SourceTableId);
        PageMetadata.SetFilter(PageType, '%1|%2', PageMetadata.PageType::List, PageMetadata.PageType::Card);

        // If there are no list or card pages for the selected table, show table fields instead.
        AreTherePagesAvailable := PageMetadata.FindSet();
        if AreTherePagesAvailable then begin
            SourcePageInfo := StrSubstNo('%1 (%2, %3)', PageMetadata.Name, PageMetadata.Id, PageMetadata.PageType);
            Rec.SetFilter("Page ID", '%1', PageMetadata.Id);
            Rec.SetFilter(FieldKind, '%1', Rec.FieldKind::PageFieldBoundToTable);
        end
        else
            Rec.SetFilter(FieldKind, '%1', Rec.FieldKind::TableField);

        Rec.SetFilter(Type, '<>%1 & <>%2 & <>%3 & <>%4 & <>%5', Rec.Type::BLOB, Rec.Type::Media, Rec.Type::MediaSet, Rec.Type::NotSupported_Binary, Rec.Type::TableFilter);
    end;

    local procedure GetExample(tableFieldId: Integer): Text
    var
        PageTableFieldFieldRef: FieldRef;
    begin
        if PageTableFieldRecRef.FieldExist(tableFieldId) then begin
            PageTableFieldFieldRef := PageTableFieldRecRef.Field(tableFieldId);
            exit(Format(PageTableFieldFieldRef.Value()));
        end;
    end;

    var
        PageMetadata: Record "Page Metadata";
        PageTableFieldRecRef: RecordRef;
        UsingTableAsSourceMsg: Label 'There are no list or card pages for the selected table, showing table fields instead.';
        SourcePageInfo: Text;
        SourcePageName: Text;
        SourcePageId: Integer;
        SourceTableId: Integer;
        SourceTableName: Text;
        SourceTableInfo: Text;
        AreTherePagesAvailable: Boolean;
        Example: Text;
        IsTableIsEmpty: Boolean;
}