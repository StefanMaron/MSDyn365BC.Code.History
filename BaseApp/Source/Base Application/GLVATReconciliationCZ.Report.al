report 11789 "G/L VAT Reconciliation CZ"
{
    DefaultLayout = RDLC;
    RDLCLayout = './GLVATReconciliationCZ.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L VAT Reconciliation';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = SORTING("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(G_L_Account__TABLECAPTION; TableCaption)
            {
            }
            column(GLAccFilter; GLAccFilter)
            {
            }
            column(G_L_Account__No__; "No.")
            {
            }
            column(G_L_Account_Name; Name)
            {
            }
            column(G_L_Entry__Amount; "G/L Entry".Amount)
            {
            }
            column(G_L_Entry___VAT_Amount_; "G/L Entry"."VAT Amount")
            {
            }
            column(G_L_VAT_ReconciliationCaption; G_L_VAT_ReconciliationCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(G_L_Entry__Posting_Date_Caption; "G/L Entry".FieldCaption("Posting Date"))
            {
            }
            column(G_L_Entry__Document_Type_Caption; G_L_Entry__Document_Type_CaptionLbl)
            {
            }
            column(G_L_Entry__Document_No__Caption; "G/L Entry".FieldCaption("Document No."))
            {
            }
            column(G_L_Entry_DescriptionCaption; "G/L Entry".FieldCaption(Description))
            {
            }
            column(G_L_Entry__VAT_Amount_Caption; "G/L Entry".FieldCaption("VAT Amount"))
            {
            }
            column(G_L_Entry__Gen__Posting_Type_Caption; G_L_Entry__Gen__Posting_Type_CaptionLbl)
            {
            }
            column(G_L_Entry__Gen__Bus__Posting_Group_Caption; G_L_Entry__Gen__Bus__Posting_Group_CaptionLbl)
            {
            }
            column(G_L_Entry__Gen__Prod__Posting_Group_Caption; G_L_Entry__Gen__Prod__Posting_Group_CaptionLbl)
            {
            }
            column(G_L_Entry_AmountCaption; "G/L Entry".FieldCaption(Amount))
            {
            }
            column(G_L_Entry__Entry_No__Caption; "G/L Entry".FieldCaption("Entry No."))
            {
            }
            column(G_L_Entry__VAT_Date_Caption; "G/L Entry".FieldCaption("VAT Date"))
            {
            }
            column(G_L_Account__No__Caption; G_L_Account__No__CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemLink = "G/L Account No." = FIELD("No.");
                DataItemTableView = SORTING("G/L Account No.", "Posting Date");
                RequestFilterFields = "Posting Date", "VAT Date";
                column(G_L_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(G_L_Entry__Document_Type_; "Document Type")
                {
                }
                column(G_L_Entry__Document_No__; "Document No.")
                {
                }
                column(G_L_Entry_Description; Description)
                {
                }
                column(G_L_Entry__VAT_Amount_; "VAT Amount")
                {
                }
                column(G_L_Entry__Gen__Posting_Type_; "Gen. Posting Type")
                {
                }
                column(G_L_Entry__Gen__Bus__Posting_Group_; "Gen. Bus. Posting Group")
                {
                }
                column(G_L_Entry__Gen__Prod__Posting_Group_; "Gen. Prod. Posting Group")
                {
                }
                column(G_L_Entry_Amount; Amount)
                {
                }
                column(G_L_Entry__Entry_No__; "Entry No.")
                {
                }
                column(G_L_Entry__VAT_Date_; "VAT Date")
                {
                }
                column(G_L_Entry_Amount_Control41; Amount)
                {
                }
                column(G_L_Entry__VAT_Amount__Control1470000; "VAT Amount")
                {
                }
                column(G_L_Entry_Amount_Control41Caption; G_L_Entry_Amount_Control41CaptionLbl)
                {
                }
                column(G_L_Entry_G_L_Account_No_; "G/L Account No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if DifferentOnly and ("Posting Date" = "VAT Date") then
                        CurrReport.Skip;
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DifferentOnly; DifferentOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Different VAT and Posting Dates Only';
                        MultiLine = true;
                        ToolTip = 'Specifies when the different vat and posting dates only is to be show';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLAccFilter := "G/L Account".GetFilters;
    end;

    var
        GLAccFilter: Text;
        DifferentOnly: Boolean;
        G_L_VAT_ReconciliationCaptionLbl: Label 'G/L VAT Reconciliation';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        G_L_Entry__Document_Type_CaptionLbl: Label 'Document Type';
        G_L_Entry__Gen__Posting_Type_CaptionLbl: Label 'Gen. Posting Type';
        G_L_Entry__Gen__Bus__Posting_Group_CaptionLbl: Label 'Gen. Bus. Posting Group';
        G_L_Entry__Gen__Prod__Posting_Group_CaptionLbl: Label 'Gen. Prod. Posting Group';
        G_L_Account__No__CaptionLbl: Label 'Account No.';
        TotalCaptionLbl: Label 'Total';
        G_L_Entry_Amount_Control41CaptionLbl: Label 'Total';
}

