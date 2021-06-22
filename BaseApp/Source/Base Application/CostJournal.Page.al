page 1108 "Cost Journal"
{
    ApplicationArea = CostAccounting;
    AutoSplitKey = true;
    Caption = 'Cost Journals';
    DataCaptionFields = "Journal Template Name";
    DelayedInsert = true;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Page,Post/Print';
    SaveValues = true;
    SourceTable = "Cost Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CostJnlBatchName; CostJnlBatchName)
            {
                ApplicationArea = CostAccounting;
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CostJnlMgt.LookupName(CostJnlBatchName, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    CostJnlMgt.CheckName(CostJnlBatchName, Rec);

                    CurrPage.SaveRecord;
                    CostJnlMgt.SetName(CostJnlBatchName, Rec);
                    CurrPage.Update(false);
                end;
            }
            repeater(Control7)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Cost Type No."; "Cost Type No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the subtype of the cost center. This is an information field and is not used for any other purposes. Choose the field to select the cost subtype.';
                }
                field("Cost Center Code"; "Cost Center Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost center code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Cost Object Code"; "Cost Object Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost object code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field(Description; Description)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a description of the cost journal entry.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the amount of the entry in the cost journal.';
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
                field("Bal. Cost Type No."; "Bal. Cost Type No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the type that a balancing entry for the journal line is posted to.';
                }
                field("Bal. Cost Center Code"; "Bal. Cost Center Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the cost center that a balancing entry for the journal line is posted to.';
                }
                field("Bal. Cost Object Code"; "Bal. Cost Object Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the cost center that a balancing entry for the journal line is posted to.';
                }
                field(LineBalance; Balance)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the balance of the cost type.';
                    Visible = false;
                }
                field("G/L Entry No."; "G/L Entry No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the entry number of the corresponding general ledger entry that is associated with this cost entry. For combined entries, the entry number of the last general ledger entry is saved in the field. This is the entry with the highest entry number.';
                    Visible = false;
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
            }
            group(Control21)
            {
                ShowCaption = false;
                fixed(Control22)
                {
                    ShowCaption = false;
                    group("Cost Type Name")
                    {
                        Caption = 'Cost Type Name';
                        field(CostTypeName; CostTypeName)
                        {
                            ApplicationArea = CostAccounting;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                    group("Bal. Cost Type Name")
                    {
                        Caption = 'Bal. Cost Type Name';
                        field(BalCostTypeName; BalCostTypeName)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Bal. Cost Type Name';
                            Editable = false;
                            ToolTip = 'Specifies the name of the balance cost type on the cost journal.';
                        }
                    }
                    group(Control27)
                    {
                        Caption = 'Balance';
                        field(Balance; LineBalance + Balance - xRec.Balance)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Balance';
                            Editable = false;
                            ToolTip = 'Specifies the balance on the cost journal line.';
                            Visible = BalanceVisible;
                        }
                    }
                    group("Total Balance")
                    {
                        Caption = 'Total Balance';
                        field(TotalBalance; TotalBalance + Balance - xRec.Balance)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Total Balance';
                            Editable = false;
                            ToolTip = 'Specifies the total balance on the cost journal.';
                            Visible = TotalBalanceVisible;
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
            group("P&ost")
            {
                Caption = 'P&ost';
                Image = PostOrder;
                action(Post)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post information in the journal to the related cost register, such as pure cost entries, internal charges between cost centers, manual allocations, and corrective entries between cost types, cost centers, and cost objects.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post", Rec);
                        CostJnlBatchName := GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
                action(TestReport)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Test Report';
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        SetRange("Journal Template Name", "Journal Template Name");
                        SetRange("Journal Batch Name", "Journal Batch Name");
                        REPORT.Run(REPORT::"Cost Acctg. Journal", true, false, Rec);
                    end;
                }
                action(PostandPrint)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Post or print information in the journal to the related cost register, such as pure cost entries, internal charges between cost centers, manual allocations, and corrective entries between cost types, cost centers, and cost objects.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post+Print", Rec);
                        CostJnlBatchName := GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Send the data in the journal to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        ODataUtility: Codeunit ODataUtility;
                    begin
                        ODataUtility.EditJournalWorksheetInExcel(CurrPage.Caption, CurrPage.ObjectId(false), "Journal Batch Name", "Journal Template Name");
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateLineBalance;
    end;

    trigger OnAfterGetRecord()
    begin
        xRec := Rec;
    end;

    trigger OnInit()
    begin
        BalanceVisible := true;
        TotalBalanceVisible := true;
        TotalBalance := 0;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine(xRec);
        xRec := Rec;
        UpdateLineBalance;
    end;

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
        JnlSelected: Boolean;
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        if ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::ODataV4 then
            exit;

        if IsOpenedFromBatch then begin
            CostJnlBatchName := "Journal Batch Name";
            CostJnlMgt.OpenJnl(CostJnlBatchName, Rec);
            exit;
        end;
        CostJnlMgt.TemplateSelection(Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        CostJnlMgt.OpenJnl(CostJnlBatchName, Rec);
    end;

    var
        CostType: Record "Cost Type";
        CostJnlMgt: Codeunit CostJnlManagement;
        ClientTypeManagement: Codeunit "Client Type Management";
        CostJnlBatchName: Code[10];
        CostTypeName: Text[100];
        BalCostTypeName: Text[100];
        LineBalance: Decimal;
        TotalBalance: Decimal;
        ShowBalance: Boolean;
        ShowTotalBalance: Boolean;
        [InDataSet]
        BalanceVisible: Boolean;
        [InDataSet]
        TotalBalanceVisible: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;

    local procedure UpdateLineBalance()
    begin
        // Update Balance
        CostJnlMgt.CalcBalance(Rec, xRec, LineBalance, TotalBalance, ShowBalance, ShowTotalBalance);
        BalanceVisible := ShowBalance;
        TotalBalanceVisible := ShowTotalBalance;

        // Cost type and bal. Cost Type
        if CostType.Get("Cost Type No.") then
            CostTypeName := CostType.Name
        else
            CostTypeName := '';

        if CostType.Get("Bal. Cost Type No.") then
            BalCostTypeName := CostType.Name
        else
            BalCostTypeName := '';
    end;
}

