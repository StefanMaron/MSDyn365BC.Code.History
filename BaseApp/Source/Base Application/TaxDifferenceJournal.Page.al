page 17306 "Tax Difference Journal"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Tax Difference Journals';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Tax Diff. Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Control305)
            {
                ShowCaption = false;
                field(CurrentJnlBatchName; CurrentJnlBatchName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batch Name';
                    Lookup = true;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord;
                        TaxDefManagement.LookupName(CurrentJnlBatchName, Rec);
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        TaxDefManagement.CheckName(CurrentJnlBatchName, Rec);
                        CurrentJnlBatchNameOnAfterVali;
                    end;
                }
            }
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the tax differences journal line.';
                }
                field("Tax Diff. Type"; "Tax Diff. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax differences type associated with the tax differences journal line.';

                    trigger OnValidate()
                    begin
                        TaxDefManagement.GetAccounts(Rec, TaxDiffName, SourceName);
                    end;
                }
                field("Tax Diff. Code"; "Tax Diff. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax differences code associated with the tax differences journal line.';

                    trigger OnValidate()
                    begin
                        TaxDefManagement.GetAccounts(Rec, TaxDiffName, SourceName);
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Tax Diff. Category"; "Tax Diff. Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax differences category associated with the tax differences journal line.';
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
                }
                field("Jurisdiction Code"; "Jurisdiction Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the jurisdiction code associated with the tax differences journal line.';
                }
                field("Norm Code"; "Norm Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the norm jurisdiction code associated with the tax differences journal line.';
                }
                field("Tax Factor"; "Tax Factor")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax factor associated with the tax differences journal line.';
                }
                field("Tax Diff. Posting Group"; "Tax Diff. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax differences posting group associated with the tax differences journal line.';
                }
                field("Amount (Base)"; "Amount (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base amount associated with the tax differences journal line.';
                }
                field("Amount (Tax)"; "Amount (Tax)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount including tax associated with the tax differences journal line.';
                }
                field(Difference; Difference)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference of the tax differences journal line.';
                }
                field("YTD Amount (Base)"; "YTD Amount (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year-to-date base amount associated with the tax differences journal line.';
                }
                field("YTD Amount (Tax)"; "YTD Amount (Tax)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year-to-date tax amount associated with the tax differences journal line.';
                }
                field("YTD Difference"; "YTD Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year-to-date difference associated with the tax differences journal line.';
                }
                field("Tax Diff. Calc. Mode"; "Tax Diff. Calc. Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax differences calculation mode associated with the tax differences journal line.';
                }
                field("Tax Amount"; "Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax amount associated with the tax differences journal line.';
                }
                field("Asset Tax Amount"; "Asset Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the asset tax amount associated with the tax differences journal line.';
                }
                field("Liability Tax Amount"; "Liability Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the liability tax amount associated with the tax differences journal line.';
                }
                field("Disposal Tax Amount"; "Disposal Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the disposal tax amount associated with the tax differences journal line.';
                }
                field("DTA Starting Balance"; "DTA Starting Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deferred tax asset (DTA) starting balance associated with the tax differences journal line.';
                }
                field("DTL Starting Balance"; "DTL Starting Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deferred tax liability (DTL) starting balance associated with the tax differences journal line.';
                }
                field("DTA Ending Balance"; "DTA Ending Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deferred tax asset (DTA) ending balance associated with the tax differences journal line.';
                }
                field("DTL Ending Balance"; "DTL Ending Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deferred tax liability (DTL) ending balance associated with the tax differences journal line.';
                }
                field("Disposal Mode"; "Disposal Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to write down the tax difference or transform it into a constant difference.';
                }
                field("Disposal Date"; "Disposal Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the disposal date of the tax differences journal line.';
                }
                field("Partial Disposal"; "Partial Disposal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the item causes differences in the expense or income code.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Reason Code"; "Reason Code")
                {
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field("Depr. Bonus Recovery"; "Depr. Bonus Recovery")
                {
                    ToolTip = 'Specifies if the line has an additional depreciation amount on fixed assets.';
                    Visible = false;
                }
            }
            group(Control1210003)
            {
                ShowCaption = false;
                label(Control1210075)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19047108;
                    ShowCaption = false;
                }
                field(TaxDiffName; TaxDiffName)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
                label(Control1210077)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19033216;
                    ShowCaption = false;
                }
                field(SourceName; SourceName)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.Update;
                    end;
                }
            }
            group("Tax Difference")
            {
                Caption = 'Tax Difference';
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = BankAccountLedger;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';

                    trigger OnAction()
                    begin
                        TaxDefManagement.JnlShowEntries(Rec);
                    end;
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';

                    trigger OnAction()
                    begin
                        TaxDefManagement.JnlPost(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        TaxDefManagement.GetAccounts(Rec, TaxDiffName, SourceName);
    end;

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine(xRec);
        Clear(ShortcutDimCode);
        Clear(TaxDiffName);
        Clear(SourceName);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        SourceName := '';
        OpenedFromBatch := ("Journal Batch Name" <> '') and ("Journal Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := "Journal Batch Name";
            TaxDefManagement.OpenJnl(CurrentJnlBatchName, Rec);
            exit;
        end;
        TaxDefManagement.TemplateSelection(PAGE::"Tax Difference Journal", 0, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        TaxDefManagement.OpenJnl(CurrentJnlBatchName, Rec);
    end;

    var
        TaxDefManagement: Codeunit TaxDiffJnlManagement;
        CurrentJnlBatchName: Code[10];
        TaxDiffName: Text[80];
        SourceName: Text[50];
        ShortcutDimCode: array[8] of Code[20];
        OpenedFromBatch: Boolean;
        Text19047108: Label 'Tax. Diff. Name';
        Text19033216: Label 'Source Name';

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord;
        TaxDefManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;
}

