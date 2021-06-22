page 391 "Extended Text List"
{
    Caption = 'Extended Text List';
    CardPageID = "Extended Text";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Extended Text Header";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the content of the extended item description.';
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field("All Language Codes"; "All Language Codes")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text should be used for all language codes. If a language code has been chosen in the Language Code field, it will be overruled by this function.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a date from which the text will be used on the item, account, resource or standard text.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a date on which the text will no longer be used on the item, account, resource or standard text.';
                }
                field("Sales Quote"; "Sales Quote")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on sales quotes.';
                    Visible = false;
                }
                field("Sales Invoice"; "Sales Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on sales invoices.';
                    Visible = false;
                }
                field("Sales Order"; "Sales Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on sales orders.';
                    Visible = false;
                }
                field("Sales Credit Memo"; "Sales Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on sales credit memos.';
                    Visible = false;
                }
                field("Purchase Quote"; "Purchase Quote")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase quotes.';
                    Visible = false;
                }
                field("Purchase Invoice"; "Purchase Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase invoices.';
                    Visible = false;
                }
                field("Purchase Order"; "Purchase Order")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase orders.';
                    Visible = false;
                }
                field("Purchase Credit Memo"; "Purchase Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase credit memos.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

