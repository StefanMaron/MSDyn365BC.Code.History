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
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim2Visible;
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
                field("Shortcut Dimension 3 Code"; "Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; "Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; "Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; "Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; "Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; "Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim8Visible;
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
                        ShowDimensions();
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

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    var
        DimensionSetIDFilter: Page "Dimension Set ID Filter";

    protected var
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;
}

