page 741 "VAT Report Subform"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = ListPart;
    SourceTable = "VAT Report Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Incl. in Report"; "Incl. in Report")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies whether to include a VAT report line in the exported version of the report that will be submitted to the tax authority.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the line number.';
                }
                field("Operation Occurred Date"; "Operation Occurred Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the date when the VAT operation occurred on the transaction.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the posting date of the document that resulted in the VAT entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the document number that resulted in the VAT entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the type of the document that resulted in the VAT entry.';
                }
                field(Type; Type)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the type of the VAT entry.';
                }
                field(Base; Base)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the amount that the VAT amount in the Amount is calculated from.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT amount for the report line. This is calculated based on the value of the Base field.';

                    trigger OnAssistEdit()
                    var
                        VATEntry: Record "VAT Entry";
                    begin
                        VATEntry.SetRange("Document No.", "Document No.");
                        VATEntry.SetRange("Document Type", "Document Type");
                        VATEntry.SetRange("Include in VAT Transac. Rep.", true);
                        VATEntry.SetRange(VATEntry."Unrealized VAT Entry No.", 0);
                        PAGE.RunModal(0, VATEntry);
                    end;
                }
                field("Amount Incl. VAT"; "Amount Incl. VAT")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the amount including VAT for this report line.';
                }
                field("Bill-to/Pay-to No."; "Bill-to/Pay-to No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number of the bill-to customer or pay-to vendor that the entry is linked to.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("Internal Ref. No."; "Internal Ref. No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the internal reference number of the VAT entry.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT registration number of the customer or vendor that the VAT entry is linked to.';
                }
                field("VAT Transaction Nature"; "VAT Transaction Nature")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies operation nature. The specific reason why the vendor should not indicate tax in the invoice.';
                }
            }
        }
    }

    actions
    {
    }
}

