page 10765 "Posted Sales Invoice - Update"
{
    Caption = 'Posted Sales Invoice - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Sales Invoice Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posted invoice number.';
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer that you shipped the items on the invoice to.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the invoice was posted.';
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field(OperationDescription; OperationDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Operation Description';
                    Editable = true;
                    MultiLine = true;
                    ToolTip = 'Specifies the Operation Description.';

                    trigger OnValidate()
                    var
                        SIIManagement: Codeunit "SII Management";
                    begin
                        SIIManagement.SplitOperationDescription(OperationDescription, "Operation Description", "Operation Description 2");
                        Validate("Operation Description");
                        Validate("Operation Description 2");
                    end;
                }
                field("Special Scheme Code"; "Special Scheme Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the Special Scheme Code.';
                }
                field("Invoice Type"; "Invoice Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the Invoice Type.';
                }
                field("ID Type"; "ID Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the ID Type.';
                }
                field("Succeeded Company Name"; "Succeeded Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the name of the company sucessor in connection with corporate restructuring.';
                }
                field("Succeeded VAT Registration No."; "Succeeded VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the VAT registration number of the company sucessor in connection with corporate restructuring.';
                }
                field("Issued By Third Party"; "Issued By Third Party")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the invoice was issued by a third party.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        xSalesInvoiceHeader := Rec;
        SIIManagement.CombineOperationDescription("Operation Description", "Operation Description 2", OperationDescription);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged then
                CODEUNIT.Run(CODEUNIT::"Sales Invoice Header - Edit", Rec);
    end;

    var
        xSalesInvoiceHeader: Record "Sales Invoice Header";
        OperationDescription: Text[500];

    local procedure RecordChanged() RecordIsChanged: Boolean
    begin
        RecordIsChanged :=
          ("Operation Description" <> xSalesInvoiceHeader."Operation Description") or
          ("Operation Description 2" <> xSalesInvoiceHeader."Operation Description 2") or
          ("Special Scheme Code" <> xSalesInvoiceHeader."Special Scheme Code") or
          ("Invoice Type" <> xSalesInvoiceHeader."Invoice Type") or
          ("ID Type" <> xSalesInvoiceHeader."ID Type") or
          ("Succeeded Company Name" <> xSalesInvoiceHeader."Succeeded Company Name") or
          ("Succeeded VAT Registration No." <> xSalesInvoiceHeader."Succeeded VAT Registration No.") or
          ("Issued By Third Party" <> xSalesInvoiceHeader."Issued By Third Party");

        OnAfterRecordIsChanged(Rec, xSalesInvoiceHeader, RecordIsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        Rec := SalesInvoiceHeader;
        Insert;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordIsChanged(var SalesInvoiceHeader: Record "Sales Invoice Header"; xSalesInvoiceHeader: Record "Sales Invoice Header"; var RecordIsChanged: Boolean)
    begin
    end;
}

