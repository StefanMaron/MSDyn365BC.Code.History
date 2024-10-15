page 10767 "Posted Purch. Cr.Memo - Update"
{
    Caption = 'Posted Purch. Cr.Memo - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Purch. Cr. Memo Hdr.";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the posted credit memo number.';
                }
                field("Buy-from Vendor Name"; "Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor';
                    Editable = false;
                    ToolTip = 'Specifies the name of the vendor who shipped the items.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date the credit memo was posted.';
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
                field("Cr. Memo Type"; "Cr. Memo Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the Credit Memo Type.';
                }
                field("Correction Type"; "Correction Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the Correction Type.';
                }
                field("Corrected Invoice No."; "Corrected Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the number of the posted invoice that you need to correct.';
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
        xPurchCrMemoHdr := Rec;
        SIIManagement.CombineOperationDescription("Operation Description", "Operation Description 2", OperationDescription);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged then
                CODEUNIT.Run(CODEUNIT::"Purch. Cr. Memo Hdr. - Edit", Rec);
    end;

    var
        xPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        OperationDescription: Text[500];

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
          (("Operation Description" <> xPurchCrMemoHdr."Operation Description") or
          ("Operation Description 2" <> xPurchCrMemoHdr."Operation Description 2") or
          ("Special Scheme Code" <> xPurchCrMemoHdr."Special Scheme Code") or
          ("Cr. Memo Type" <> xPurchCrMemoHdr."Cr. Memo Type") or
          ("Corrected Invoice No." <> xPurchCrMemoHdr."Corrected Invoice No.") or
          ("Correction Type" <> xPurchCrMemoHdr."Correction Type") or
          ("ID Type" <> xPurchCrMemoHdr."ID Type") or
          ("Succeeded Company Name" <> xPurchCrMemoHdr."Succeeded Company Name") or
          ("Succeeded VAT Registration No." <> xPurchCrMemoHdr."Succeeded VAT Registration No."));
        OnAfterRecordChanged(Rec, xPurchCrMemoHdr, IsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        Rec := PurchCrMemoHdr;
        Insert;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; xPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var IsChanged: Boolean)
    begin
    end;
}

