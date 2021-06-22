page 1207 "Direct Debit Collections"
{
    AdditionalSearchTerms = 'collect customer payment';
    ApplicationArea = Suite;
    Caption = 'Direct Debit Collections';
    DataCaptionFields = "No.", Identifier, "Created Date-Time";
    Editable = false;
    PageType = List;
    SourceTable = "Direct Debit Collection";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Identifier; Identifier)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, together with the number series, which direct debit collection a direct-debit collection entry is related to.';
                }
                field("FORMAT(""Created Date-Time"")"; Format("Created Date-Time"))
                {
                    ApplicationArea = Suite;
                    Caption = 'Created Date-Time';
                    ToolTip = 'Specifies when the direct debit collection was created.';
                }
                field("Created by User"; "Created by User")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which user created the direct debit collection.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the status of the direct debit collection. The following options exist.';
                }
                field("No. of Transfers"; "No. of Transfers")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how many direct debit transactions have been performed for the direct debit collection.';
                }
                field("To Bank Account No."; "To Bank Account No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the bank account that the direct debit collection will be transferred to.';
                }
                field("To Bank Account Name"; "To Bank Account Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the bank account that the direct debit collection will be transferred to.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control12; Notes)
            {
                ApplicationArea = Notes;
            }
            systempart(Control13; Links)
            {
                ApplicationArea = RecordLinks;
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(NewCollection)
            {
                ApplicationArea = Suite;
                Caption = 'Create Direct Debit Collection';
                Image = NewInvoice;
                Promoted = true;
                PromotedCategory = New;
                RunObject = Report "Create Direct Debit Collection";
                ToolTip = 'Create a direct-debit collection to collect invoice payments directly from a customer''s bank account based on direct-debit mandates.';
            }
        }
        area(processing)
        {
            action(Export)
            {
                ApplicationArea = Suite;
                Caption = 'Export Direct Debit File';
                Image = ExportFile;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Save the entries for the direct-debit collection to a file that you send or upload to your electronic bank for processing.';

                trigger OnAction()
                begin
                    Export;
                end;
            }
            action(Close)
            {
                ApplicationArea = Suite;
                Caption = 'Close Collection';
                Image = Close;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Close a direct-debit collection so you begin to post payment receipts for related sales invoices. Once closed, you cannot register payments for the collection.';

                trigger OnAction()
                begin
                    CloseCollection;
                end;
            }
            action(Post)
            {
                ApplicationArea = Suite;
                Caption = 'Post Payment Receipts';
                Ellipsis = true;
                Image = ReceivablesPayables;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Post receipts of a payment for sales invoices. You can do this after the direct-debit collection is successfully processed by the bank.';

                trigger OnAction()
                var
                    PostDirectDebitCollection: Report "Post Direct Debit Collection";
                begin
                    TestField(Status, Status::"File Created");
                    PostDirectDebitCollection.SetCollectionEntry("No.");
                    PostDirectDebitCollection.Run;
                end;
            }
        }
        area(navigation)
        {
            action(Entries)
            {
                ApplicationArea = Suite;
                Caption = 'Direct Debit Collect. Entries';
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Direct Debit Collect. Entries";
                RunPageLink = "Direct Debit Collection No." = FIELD("No.");
                ShortCutKey = 'Return';
                ToolTip = 'View and edit entries that are generated for the direct-debit collection.';
            }
        }
    }
}

