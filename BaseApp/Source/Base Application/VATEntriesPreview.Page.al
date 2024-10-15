page 123 "VAT Entries Preview"
{
    Caption = 'VAT Entries Preview';
    Editable = false;
    PageType = List;
    SourceTable = "VAT Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT entry''s posting date.';
                }
                field("VAT Date"; "VAT Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT entry''s VAT date.';
                }
                field("Original Document VAT Date"; "Original Document VAT Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT entry''s Original Document VAT Date.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the VAT entry.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the external document number on the VAT entry.';
                }
                field("Pmt.Disc. Tax Corr.Doc. No."; "Pmt.Disc. Tax Corr.Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the related credit note, Payment discount tax corrective document.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value code that the entry is linked to.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value code that the entry is linked to.';
                    Visible = false;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that the VAT entry belongs to.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the VAT entry.';
                }
                field("Advance Base"; "Advance Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the advance base of the VAT entry.';
                    Visible = false;
                }
                field(Base; Base)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the VAT amount (the amount shown in the Amount field) is calculated from.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the VAT entry in LCY.';
                }
                field("Advance Exch. Rate Difference"; "Advance Exch. Rate Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the advance exchange rate difference of the VAT entry.';
                    Visible = false;
                }
                field("VAT % (Non Deductible)"; "VAT % (Non Deductible)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT % (non deductible) of the VAT entry.';
                    Visible = false;
                }
                field("VAT Base (Non Deductible)"; "VAT Base (Non Deductible)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT base (non deductible) of the VAT entry.';
                    Visible = false;
                }
                field("VAT Amount (Non Deductible)"; "VAT Amount (Non Deductible)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount (non deductible) of the VAT entry.';
                    Visible = false;
                }
                field("VAT Difference"; "VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference between the calculated VAT amount and a VAT amount that you have entered manually.';
                    Visible = false;
                }
                field("Additional-Currency Base"; "Additional-Currency Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the VAT amount is calculated from if you post in an additional reporting currency.';
                    Visible = false;
                }
                field("Additional-Currency Amount"; "Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the VAT entry. The amount is in the additional reporting currency.';
                    Visible = false;
                }
                field("Add.-Curr. VAT Difference"; "Add.-Curr. VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies, in the additional reporting currency, the VAT difference that arises when you make a correction to a VAT amount on a sales or purchase document.';
                    Visible = false;
                }
                field("Unrealized Amount"; "Unrealized Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unrealized amount of the VAT entry.';
                    Visible = false;
                }
                field("Unrealized Base"; "Unrealized Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unrealized base of the VAT entry.';
                    Visible = false;
                }
                field("Remaining Unrealized Amount"; "Remaining Unrealized Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining unrealized amount of the VAT entry.';
                    Visible = false;
                }
                field("Remaining Unrealized Base"; "Remaining Unrealized Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining unrealized base of the VAT entry.';
                    Visible = false;
                }
                field("VAT Calculation Type"; "VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
                }
                field("Bill-to/Pay-to No."; "Bill-to/Pay-to No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bill-to customer or pay-to vendor that the entry is linked to.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT registration number of the customer or vendor that the entry is linked to.';
                    Visible = false;
                }
                field("Ship-to/Order Address Code"; "Ship-to/Order Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address code of the ship-to customer or order-from vendor that the entry is linked to.';
                    Visible = false;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("EU 3-Party Trade"; "EU 3-Party Trade")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
                }
                field("EU 3-Party Intermediate Role"; "EU 3-Party Intermediate Role")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the entry was part of a 3-party intermediate role.';
                }
                field(Closed; Closed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the VAT entry has been closed by the Calc. and Post VAT Settlement batch job.';
                }
                field("Closed by Entry No."; "Closed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the VAT entry that has closed the entry, if the VAT entry was closed with the Calc. and Post VAT Settlement batch job.';
                }
                field("Postponed VAT"; "Postponed VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postponed VAT of the VAT entry.';
                }
                field("Internal Ref. No."; "Internal Ref. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal reference number for the line.';
                }
                field(Reversed; Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry has been part of a reverse transaction.';
                    Visible = false;
                }
                field("Reversed by Entry No."; "Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the correcting entry. If the field Specifies a number, the entry cannot be reversed again.';
                    Visible = false;
                }
                field("Reversed Entry No."; "Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the original entry that was undone by the reverse transaction.';
                    Visible = false;
                }
                field("EU Service"; "EU Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this VAT entry is to be reported as a service in the periodic VAT reports.';
                    Visible = false;
                }
                field("VAT Settlement No."; "VAT Settlement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT settlement number of the VAT settlement that the entry is linked to.';
                    Visible = false;
                }
                field("VAT Control Report Line No."; "VAT Control Report Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT control report line number of the VAT control line that the entry is linked to.';
                }
            }
        }
    }

    actions
    {
    }

    procedure Set(var TempVATEntry: Record "VAT Entry" temporary)
    begin
        if TempVATEntry.FindSet then
            repeat
                Rec := TempVATEntry;
                Insert;
            until TempVATEntry.Next = 0;
    end;
}

