page 1880 "VAT Assisted Setup Template"
{
    Caption = 'VAT Assisted Setup Template';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "VAT Assisted Setup Templates";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a description of the VAT assisted setup.';
                }
                field("Default VAT Bus. Posting Grp"; Rec."Default VAT Bus. Posting Grp")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default VAT business posting group for the customers and vendors.';
                    Visible = VATBusPostingVisible;
                }
                field("Default VAT Prod. Posting Grp"; Rec."Default VAT Prod. Posting Grp")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default VAT production posting group for the customers and vendors.';
                    Visible = VATProdPostingVisible;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        PopulateRecFromTemplates();
        ShowCustomerTemplate();
    end;

    var
        VATProdPostingVisible: Boolean;
        VATBusPostingVisible: Boolean;

    procedure ShowCustomerTemplate()
    begin
        ResetVisibility();
        VATBusPostingVisible := true;
        SetRange("Table ID", DATABASE::Customer);
        CurrPage.Update();
    end;

    procedure ShowVendorTemplate()
    begin
        ResetVisibility();
        VATBusPostingVisible := true;
        SetRange("Table ID", DATABASE::Vendor);
        CurrPage.Update();
    end;

    procedure ShowItemTemplate()
    begin
        ResetVisibility();
        VATProdPostingVisible := true;
        SetRange("Table ID", DATABASE::Item);
        CurrPage.Update();
    end;

    local procedure ResetVisibility()
    begin
        VATBusPostingVisible := false;
        VATProdPostingVisible := false;
    end;
}

