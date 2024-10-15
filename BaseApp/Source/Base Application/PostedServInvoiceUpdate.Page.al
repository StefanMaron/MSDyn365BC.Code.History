page 10768 "Posted Serv. Invoice - Update"
{
    Caption = 'Posted Service Invoice - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Service Invoice Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the posted invoice number.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Service;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer on the service invoice.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when the invoice was posted.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the country/region of the address.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the country/region code of the customer''s billing address.';
                }
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

                    trigger OnValidate()
                    begin
                        SIIFirstSummaryDocNo := '';
                        SIILastSummaryDocNo := '';
                    end;
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
                field("SII First Summary Doc. No."; SIIFirstSummaryDocNo)
                {
                    Caption = 'First Summary Doc. No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first number in the series of the summary entry. This field applies to F4-type invoices only.';
                    trigger OnValidate()
                    begin
                        SetSIIFirstSummaryDocNo(SIIFirstSummaryDocNo);
                    end;
                }
                field("SII Last Summary Doc. No."; SIILastSummaryDocNo)
                {
                    Caption = 'Last Summary Doc. No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last number in the series of the summary entry. This field applies to F4-type invoices only.';
                    trigger OnValidate()
                    begin
                        SetSIILastSummaryDocNo(SIILastSummaryDocNo);
                    end;
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
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
        xServiceInvoiceHeader := Rec;
        SIIManagement.CombineOperationDescription("Operation Description", "Operation Description 2", OperationDescription);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Service Invoice Header - Edit", Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        SIIFirstSummaryDocNo := Copystr(GetSIIFirstSummaryDocNo(), 1, 35);
        SIILastSummaryDocNo := Copystr(GetSIILastSummaryDocNo(), 1, 35);
    end;

    var
        xServiceInvoiceHeader: Record "Service Invoice Header";
        OperationDescription: Text[500];
        SIIFirstSummaryDocNo: Text[35];
        SIILastSummaryDocNo: Text[35];

    local procedure RecordChanged() RecordIsChanged: Boolean
    begin
        RecordIsChanged :=
          ("Country/Region Code" <> xServiceInvoiceHeader."Country/Region Code") or
          ("Bill-to Country/Region Code" <> xServiceInvoiceHeader."Bill-to Country/Region Code") or
          ("Ship-to Country/Region Code" <> xServiceInvoiceHeader."Ship-to Country/Region Code") or
          ("Operation Description" <> xServiceInvoiceHeader."Operation Description") or
          ("Operation Description 2" <> xServiceInvoiceHeader."Operation Description 2") or
          ("Special Scheme Code" <> xServiceInvoiceHeader."Special Scheme Code") or
          ("Invoice Type" <> xServiceInvoiceHeader."Invoice Type") or
          ("ID Type" <> xServiceInvoiceHeader."ID Type") or
          ("Succeeded Company Name" <> xServiceInvoiceHeader."Succeeded Company Name") or
          ("Succeeded VAT Registration No." <> xServiceInvoiceHeader."Succeeded VAT Registration No.") or
          ("Issued By Third Party" <> xServiceInvoiceHeader."Issued By Third Party") OR
          (GetSIIFirstSummaryDocNo() <> xServiceInvoiceHeader.GetSIIFirstSummaryDocNo()) OR
          (GetSIILastSummaryDocNo() <> xServiceInvoiceHeader.GetSIILastSummaryDocNo());

        OnAfterRecordIsChanged(Rec, xServiceInvoiceHeader, RecordIsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        Rec := ServiceInvoiceHeader;
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordIsChanged(var ServiceInvoiceHeader: Record "Service Invoice Header"; xServiceInvoiceHeader: Record "Service Invoice Header"; var RecordIsChanged: Boolean)
    begin
    end;
}

