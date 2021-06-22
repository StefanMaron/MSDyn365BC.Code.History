page 850 "Cash Flow Forecast Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Flow Ledger Entries';
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Entry';
    SourceTable = "Cash Flow Forecast Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1000)
            {
                ShowCaption = false;
                field("Cash Flow Date"; "Cash Flow Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cash flow date that the entry is posted to.';
                }
                field(Overdue; Overdue)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry is related to an overdue payment. ';
                }
                field("Cash Flow Forecast No."; "Cash Flow Forecast No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number for the cash flow forecast.';
                }
                field("Cash Flow Account No."; "Cash Flow Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the cash flow account that the forecast entry is posted to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document that represents the forecast entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the cash flow forecast entry.';

                    trigger OnDrillDown()
                    begin
                        ShowSource(false);
                    end;
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type that applies to the source number that is shown in the Source No. field.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';

                    trigger OnDrillDown()
                    begin
                        ShowSource(true);
                    end;
                }
                field("Payment Discount"; "Payment Discount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the possible payment discount for the cash flow forecast.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the forecast line in LCY. Revenues are entered without a plus or minus sign. Expenses are entered with a minus sign.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Dimension Set ID"; "Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter);
                    end;
                }
                action(GLDimensionOverview)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'G/L Dimension Overview';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'View an overview of general ledger entries and dimensions.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"CF Entries Dim. Overview", Rec);
                    end;
                }
            }
            action(ShowSource)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show';
                Image = View;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'View the actual cash flow forecast entries.';

                trigger OnAction()
                begin
                    ShowSource(false);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(Next(Steps));
    end;

    var
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
}

