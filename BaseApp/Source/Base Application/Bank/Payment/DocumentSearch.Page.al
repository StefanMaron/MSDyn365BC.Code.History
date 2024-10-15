namespace Microsoft.Bank.Payment;

page 985 "Document Search"
{
    Caption = 'Document Search';
    PageType = Card;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            group("Search Criteria")
            {
                Caption = 'Search Criteria';
                field(DocumentNo; DocumentNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the number of the document that you are searching for.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the amounts that you want to search for when you search open documents.';

                    trigger OnValidate()
                    begin
                        Warning := PaymentRegistrationMgt.SetToleranceLimits(Amount, AmountTolerance, ToleranceTxt);
                    end;
                }
                field(AmountTolerance; AmountTolerance)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Amount Tolerance %';
                    MaxValue = 100;
                    MinValue = 0;
                    ToolTip = 'Specifies the range of amounts that you want to search within when you search open documents.';

                    trigger OnValidate()
                    begin
                        Warning := PaymentRegistrationMgt.SetToleranceLimits(Amount, AmountTolerance, ToleranceTxt)
                    end;
                }
            }
            group(Information)
            {
                Caption = 'Information';
                fixed(Control9)
                {
                    ShowCaption = false;
                    group(Control8)
                    {
                        ShowCaption = false;
                        field(Warning; Warning)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                            Style = Strong;
                            ToolTip = 'Specifies warnings in connection with the search.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Action12)
            {
                Caption = 'Search';
                action(Search)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Search';
                    Image = Navigate;
                    ToolTip = 'Search for unposted documents that have the specified numbers or amount.';

                    trigger OnAction()
                    begin
                        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, DocumentNo, Amount, AmountTolerance);
                        PAGE.Run(PAGE::"Document Search Result", TempDocumentSearchResult);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Search_Promoted; Search)
                {
                }
            }
        }
    }

    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        Warning: Text;
        DocumentNo: Code[20];
        Amount: Decimal;
        AmountTolerance: Decimal;
#pragma warning disable AA0470
        ToleranceTxt: Label 'The program will search for documents with amounts between %1 and %2.';
#pragma warning restore AA0470
}

