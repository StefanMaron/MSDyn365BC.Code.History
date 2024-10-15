page 1600 "Outlook Mail Engine"
{
    Caption = 'Outlook Mail Engine';
    DelayedInsert = false;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Office Add-in Context";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Email; Email)
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the Outlook contact.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the display name of the Outlook contact.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type that the involved document belongs to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved document.';
                }
                field(Company; Company)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnOpenPage()
    var
        [RunOnClient]
        OfficeHost: DotNet OfficeHost;
    begin
        if OfficeHost.IsAvailable then begin
            OfficeHost := OfficeHost.Create;
            OfficeMgt.InitializeHost(OfficeHost, OfficeHost.HostType);
        end;

        GetDetailsFromFilters;
        if Email = 'donotreply@contoso.com' then
            Page.Run(Page::"Office Welcome Dlg")
        else
            OfficeMgt.InitializeContext(Rec);

        CurrPage.Close;
        OfficeMgt.CloseEnginePage;
    end;

    var
        OfficeMgt: Codeunit "Office Management";

    local procedure GetDetailsFromFilters()
    var
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.GetTable(Rec);
        for i := 1 to RecRef.FieldCount do
            ParseFilter(RecRef.FieldIndex(i));
        RecRef.SetTable(Rec);
    end;

    local procedure ParseFilter(FieldRef: FieldRef)
    var
        FilterPrefixRegEx: DotNet Regex;
        SingleQuoteRegEx: DotNet Regex;
        "Filter": Text;
        OptionValue: Integer;
    begin
        FilterPrefixRegEx := FilterPrefixRegEx.Regex('^@\*([^\\]+)\*$');
        SingleQuoteRegEx := SingleQuoteRegEx.Regex('^''([^\\]+)''$');

        Filter := FieldRef.GetFilter;
        Filter := FilterPrefixRegEx.Replace(Filter, '$1');
        Filter := SingleQuoteRegEx.Replace(Filter, '$1');
        if Filter <> '' then begin
            if Format(FieldRef.Type) = 'Option' then
                while true do begin
                    OptionValue += 1;
                    if UpperCase(Filter) = UpperCase(SelectStr(OptionValue, FieldRef.OptionCaption)) then begin
                        FieldRef.Value := OptionValue - 1;
                        exit;
                    end;
                end
            else
                FieldRef.Value(Filter);
        end;
    end;
}

