pageextension 18448 "GST Posted Service Credit Memo" extends "Posted Service Credit Memo"
{
    layout
    {
        addfirst(factboxes)
        {
            part(TaxInformation; "Tax Information Factbox")
            {
                Provider = ServCrMemoLines;
                SubPageLink = "Table ID Filter" = const(5995), "Document No. Filter" = field("Document No."), "Line No. Filter" = field("Line No.");
                ApplicationArea = Basic, Suite;
            }
        }
        addafter("Foreign Trade")
        {
            group(GST)
            {
                field("Nature of Supply"; Rec."Nature of Supply")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the nature of GST transaction. For example, B2B/B2C.';
                }
                field("GST Customer Type"; Rec."GST Customer Type")
                {
                    ApplicationArea = Basic, Suite;
                    Tooltip = 'Specifies the type of the customer. For example, Registered/Unregistered/Export/Exempted/SEZ Unit/SEZ Development etc.';
                }
                field("Invoice Type"; Rec."Invoice Type")
                {
                    ApplicationArea = Basic, Suite;
                    Tooltip = 'Specifies the invoice type on the service document. For example, Bill of supply, Export, Supplementary, Debit Note, Non-GST and Taxable.';
                }
                field("GST Without Payment of Duty"; Rec."GST Without Payment of Duty")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether with or without payment of duty.';
                }
                field("Bill Of Export No."; Rec."Bill Of Export No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bill of export number. It is a document number which is submitted to custom department .';
                }
                field("Bill Of Export Date"; Rec."Bill Of Export Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry date defined in bill of export document.';
                }
                field("Reference Invoice No."; Rec."Reference Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Reference Invoice number.';
                }
                field("Rate Change Applicable"; Rec."Rate Change Applicable")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if rate change is applicable on the service document.';
                }
                field("Supply Finish Date"; Rec."Supply Finish Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the supply finish date. For example, Before rate change/After rate change.';
                }
                field("Payment Date"; Rec."Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment date. For example, Before rate change/After rate change.';
                }
                field("GST Inv. Rounding Precision"; Rec."GST Inv. Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies Rounding Precision on the service document.';
                }
                field("GST Inv. Rounding Type"; Rec."GST Inv. Rounding Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies Rounding Type on the service document.';
                }
            }
        }
    }
}