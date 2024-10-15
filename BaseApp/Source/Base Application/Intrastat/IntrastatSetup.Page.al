page 328 "Intrastat Setup"
{
    ApplicationArea = BasicEU;
    Caption = 'Intrastat Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    SourceTable = "Intrastat Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Report Receipts"; Rec."Report Receipts")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies that you must include arrivals of received goods in Intrastat reports.';
                }
                field("Report Shipments"; Rec."Report Shipments")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies that you must include shipments of dispatched items in Intrastat reports.';
                }
                field("Intrastat Contact Type"; Rec."Intrastat Contact Type")
                {
                    ApplicationArea = BasicEU;
                    OptionCaption = ' ,Contact,Vendor';
                    ToolTip = 'Specifies the Intrastat contact type.';

                    trigger OnValidate()
                    begin
                        SetupCompleted()
                    end;
                }
                field("Intrastat Contact No."; Rec."Intrastat Contact No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the Intrastat contact.';

                    trigger OnValidate()
                    begin
                        SetupCompleted()
                    end;
                }
#if not CLEAN19
                field("Use Advanced Checklist"; Rec."Use Advanced Checklist")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies if you want to use the advanced Intrastat checklist setup instead of the simpler setup.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '19.0';
                    ObsoleteReason = 'Replaced by Advanced Intrastat Checklist';
                }
#endif
                field("Company VAT No. on File"; "Company VAT No. on File")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the company''s VAT registration number exports to the Intrastat file. 0 is the value of the VAT Reg. No. field, 1 adds the EU country code as a prefix, and 2 removes the EU country code.';
                }
                field("Vend. VAT No. on File"; "Vend. VAT No. on File")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how a vendor''s VAT registration number exports to the Intrastat file. 0 is the value of the VAT Reg. No. field, 1 adds the EU country code as a prefix, and 2 removes the EU country code.';
                }
                field("Cust. VAT No. on File"; "Cust. VAT No. on File")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how a customer''s VAT registration number exports to the Intrastat file. 0 is the value of the VAT Reg. No. field, 1 adds the EU country code as a prefix, and 2 removes the EU country code.';
                }
            }
            group("Default Transactions")
            {
                Caption = 'Default Transactions';
#if not CLEAN21
                field("Default Transaction Type"; "Default Trans. - Purchase")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the default transaction type for regular sales shipments and service shipments, and purchase receipts.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteTag = '21.0';
                    ObsoleteReason = 'Replaced by Default Transaction Specification';
                }
                field("Default Trans. Type - Returns"; "Default Trans. - Return")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the default transaction type for sales returns and service returns, and purchase returns';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteTag = '21.0';
                    ObsoleteReason = 'Replaced by Default Transaction Specification';
                }
#endif
                field("Default Trans. Spec. Code"; "Default Trans. Spec. Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the default transaction specification for regular sales shipments and service shipments, and purchase receipts.';
                }
                field("Default Trans. Spec. Ret. Code"; "Default Trans. Spec. Ret. Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the default transaction specification for sales returns and service returns, and purchase returns';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
#if not CLEAN19
            action(IntrastatChecklistSetup)
            {
                ApplicationArea = BasicEU;
                Caption = 'Intrastat Checklist Setup';
                Image = Column;
                RunObject = Page "Intrastat Checklist Setup";
                ToolTip = 'View and edit fields to be verified by the Intrastat journal check.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by Advanced Intrastat Checklist';
                ObsoleteTag = '19.0';
            }
#endif
            action(AdvancedIntrastatChecklistSetup)
            {
                ApplicationArea = BasicEU;
                Caption = 'Advanced Intrastat Checklist Setup';
                Image = Column;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Advanced Intrastat Checklist";
                ToolTip = 'View and edit fields to be verified by the Intrastat journal check.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('0000FAS', IntrastatTok, Enum::"Feature Uptake Status"::Discovered);
        Rec.Init();
        if not Rec.Get() then
            Rec.Insert(true);
    end;

    local procedure SetupCompleted()
    begin
        if Rec."Intrastat Contact No." <> '' then
            FeatureTelemetry.LogUptake('0000FAD', IntrastatTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        IntrastatTok: Label 'Intrastat', Locked = true;
}

