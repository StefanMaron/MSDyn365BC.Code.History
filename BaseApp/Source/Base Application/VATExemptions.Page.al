page 12100 "VAT Exemptions"
{
    Caption = 'VAT Exemptions';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "VAT Exemption";

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("VAT Exempt. Starting Date"; "VAT Exempt. Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the start date for the VAT exemption is valid.';
                }
                field("VAT Exempt. Ending Date"; "VAT Exempt. Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the end date for the VAT exemption is valid.';
                }
                field("VAT Exempt. No."; "VAT Exempt. No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the identification number of the VAT exemption.';
                    Visible = VATExemptNoVisible;
                }
                field("VAT Exempt. Date"; "VAT Exempt. Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the effective date of the VAT exemption.';
                    Visible = VATExemptDateVisible;
                }
                field("VAT Exempt. Int. Registry No."; "VAT Exempt. Int. Registry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registry number of the VAT exemption.';

                    trigger OnAssistEdit()
                    var
                        NoSeriesMgt: Codeunit NoSeriesManagement;
                    begin
                        NoSeriesMgt.LookupSeries(GetVATExemptionNos, "No. Series");
                        NoSeriesMgt.SetSeries("VAT Exempt. Int. Registry No.")
                    end;
                }
                field("VAT Exempt. Int. Registry Date"; "VAT Exempt. Int. Registry Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registry date of the VAT exemption.';
                }
                field("VAT Exempt. Office"; "VAT Exempt. Office")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the office that the VAT exemption applies to.';
                }
                field("Declared Operations Up To Amt."; "Declared Operations Up To Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount which has been declared through a declaration of intent.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Export Decl. of Intent")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Decl. of Intent';
                Image = ExportElectronicDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Export the declaration of intent.';

                trigger OnAction()
                var
                    DeclarationOfIntentExport: Page "Declaration of Intent Export";
                begin
                    TestField(Type, Type::Vendor);
                    DeclarationOfIntentExport.Initialize(Rec);
                    DeclarationOfIntentExport.Run;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        VATExemptDateVisible := true;
        VATExemptNoVisible := true;
    end;

    trigger OnOpenPage()
    begin
        UpdateForm;
    end;

    var
        [InDataSet]
        VATExemptNoVisible: Boolean;
        [InDataSet]
        VATExemptDateVisible: Boolean;

    local procedure GetVATExemptionNos(): Code[20]
    var
        PurchasesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeries: Code[20];
    begin
        if GetFilter(Type) = Format(Type::Customer) then begin
            SalesSetup.Get;
            NoSeries := SalesSetup."VAT Exemption Nos.";
        end else begin // Vendor
            PurchasesSetup.Get;
            NoSeries := PurchasesSetup."VAT Exemption Nos.";
        end;

        exit(NoSeries);
    end;

    [Scope('OnPrem')]
    procedure UpdateForm()
    begin
        VATExemptNoVisible := GetRangeMin(Type) <> Type::Vendor;
        VATExemptDateVisible := GetRangeMin(Type) <> Type::Vendor;
    end;
}

