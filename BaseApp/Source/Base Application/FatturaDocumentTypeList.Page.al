page 12206 "Fattura Document Type List"
{
    ApplicationArea = Basic, Suite;
    PageType = List;
    SourceTable = "Fattura Document Type";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type code that will be exported to the XML file.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the document type. You can enter a maximum of 250 characters, both numbers and letters.';
                }
                field(Invoice; Invoice)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that is the default for invoices.';
                }
                field("Credit Memo"; "Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that is the default for credit memos.';
                }
                field("Self-Billing"; "Self-Billing")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that is the default for self-billing documents.';
                }
                field(Prepayment; Prepayment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that is the default for prepayments.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        FatturaDocHelper.InsertFatturaDocumentTypeList();
    end;
}

