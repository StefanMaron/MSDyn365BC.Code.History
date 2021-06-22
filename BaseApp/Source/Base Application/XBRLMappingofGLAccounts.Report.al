report 506 "XBRL Mapping of G/L Accounts"
{
    DefaultLayout = RDLC;
    RDLCLayout = './XBRLMappingofGLAccounts.rdlc';
    ApplicationArea = XBRL;
    Caption = 'XBRL Mapping of G/L Accounts';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("XBRL Taxonomy"; "XBRL Taxonomy")
        {
            RequestFilterFields = Name;
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(Name_XBRLTaxonomy; Name)
            {
            }
            column(Description_XBRLTaxonomy; Description)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(GLAccountCaption; GLAccountCaptionLbl)
            {
            }
            column(TaxonomyNameCaption; TaxonomyNameCaptionLbl)
            {
            }
            dataitem("XBRL Taxonomy Line"; "XBRL Taxonomy Line")
            {
                DataItemLink = "XBRL Taxonomy Name" = FIELD(Name);
                DataItemTableView = SORTING("XBRL Taxonomy Name", "Presentation Order") ORDER(Ascending);
                column(LineNo_XBRLTaxonomyLine; "Line No.")
                {
                    IncludeCaption = true;
                }
                column(Level; PadStr('', Level * 2) + Label)
                {
                }
                column(SrcType_XBRLTaxonomyLine; "Source Type")
                {
                    IncludeCaption = true;
                }
                column(ConstAmt_XBRLTaxonomyLine; "Constant Amount")
                {
                    IncludeCaption = true;
                }
                column(Descrip_XBRLTaxonomyLine; Description)
                {
                    IncludeCaption = true;
                }
                column(XBRLTaxName_XBRLTaxLine; "XBRL Taxonomy Name")
                {
                }
                column(LabelCaption; LabelCaptionLbl)
                {
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = SORTING(Number) ORDER(Ascending) WHERE(Number = CONST(1));
                    column(WarningStr; WarningLbl + ' ' + WarningStr)
                    {
                    }
                    column(WarningStr1; WarningStr1)
                    {
                    }
                    column(Warning; WarningLbl)
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if WarningStr = '' then
                            CurrReport.Break();
                    end;
                }
                dataitem("XBRL G/L Map Line"; "XBRL G/L Map Line")
                {
                    DataItemLink = "XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"), "XBRL Taxonomy Line No." = FIELD("Line No.");
                    DataItemTableView = SORTING("XBRL Taxonomy Name", "XBRL Taxonomy Line No.", "Line No.") ORDER(Ascending);
                    column(GLAccFilter_XBRLGLMapLine; "G/L Account Filter")
                    {
                        IncludeCaption = true;
                    }
                    column(TimeframeType_XBRLGLMapLine; "Timeframe Type")
                    {
                        IncludeCaption = true;
                    }
                    column(AmtType_XBRLGLMapLine; "Amount Type")
                    {
                        IncludeCaption = true;
                    }
                    column(NormalBal_XBRLGLMapLine; "Normal Balance")
                    {
                        IncludeCaption = true;
                    }
                    column(NumGLMapLine; NumGLMapLine)
                    {
                    }
                    column(TotalNumGLMapLine; TotalNumGLMapLine)
                    {
                    }
                    column(LineNo_XBRLGLMapLine; "Line No.")
                    {
                    }
                    column(GLMappingCaption; GLMappingCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if "G/L Account Filter" <> '' then begin
                            TempGLAcc1.SetFilter("No.", "G/L Account Filter");
                            TempGLAcc1.DeleteAll();
                            TempGLAcc1.Reset();

                            TempGLAcc.SetFilter("No.", "G/L Account Filter");
                            if TempGLAcc.Find('-') then
                                repeat
                                    TempGLAcc2 := TempGLAcc;
                                    TempGLAcc2.Totaling := Format("XBRL Taxonomy Line No.");
                                    TempGLAcc2.Blocked := false;
                                    if not TempGLAcc2.Insert() then begin
                                        TempGLAcc2.Get(TempGLAcc."No.");
                                        if MaxStrLen(TempGLAcc2.Totaling) >
                                           StrLen(TempGLAcc2.Totaling + Format("XBRL Taxonomy Line No."))
                                        then begin
                                            TempGLAcc2.Totaling := TempGLAcc2.Totaling + ',' + Format("XBRL Taxonomy Line No.");
                                            TempGLAcc2.Blocked := true;
                                            TempGLAcc2.Modify();
                                        end;
                                    end;
                                until TempGLAcc.Next = 0;
                        end;

                        NumGLMapLine := NumGLMapLine + 1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        NumGLMapLine := 0;
                        TotalNumGLMapLine := Count;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields(Label, Notes, "G/L Map Lines", Rollup);
                    WarningStr := '';
                    if "G/L Map Lines" and ("Source Type" <> "Source Type"::"General Ledger") then
                        WarningStr := WarningStr + StrSubstNo(Text001, FieldCaption("Source Type"), Format("Source Type")) + '  ';
                    if ("Constant Amount" <> 0) and ("Source Type" <> "Source Type"::Constant) then
                        WarningStr :=
                          WarningStr +
                          StrSubstNo(Text002, FieldCaption("Constant Amount"), FieldCaption("Source Type"), Format("Source Type")) + ' ';

                    WarningStr1 := WarningStr;
                end;
            }
            dataitem(UnusedGLAccLoop; "Integer")
            {
                DataItemTableView = SORTING(Number) ORDER(Ascending) WHERE(Number = FILTER(1 ..));
                column(GLAcc1IncomeBalance; Format(TempGLAcc1."Income/Balance"))
                {
                }
                column(TempGLAcc1Name; TempGLAcc1.Name)
                {
                }
                column(TempGLAcc1No; TempGLAcc1."No.")
                {
                }
                column(GLAccTaxonomyLineCaption; GLAccTaxonomyLineCaptionLbl)
                {
                }
                column(IncomeBalCaption; IncomeBalCaptionLbl)
                {
                }
                column(NameCaption; NameCaptionLbl)
                {
                }
                column(NoCaption; NoCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        More := TempGLAcc1.Find('-')
                    else
                        More := TempGLAcc1.Next <> 0;
                    if not More then
                        CurrReport.Break();
                end;
            }
            dataitem(DuplicateGLAccLoop; "Integer")
            {
                DataItemTableView = SORTING(Number) ORDER(Ascending) WHERE(Number = FILTER(1 ..));
                column(GLAcc2IncomeBalance; Format(TempGLAcc2."Income/Balance"))
                {
                }
                column(TempGLAcc2Name; TempGLAcc2.Name)
                {
                }
                column(TempGLAcc2No; TempGLAcc2."No.")
                {
                }
                column(TempGLAcc2Totaling; TempGLAcc2.Totaling)
                {
                }
                column(GLAccTaxonomyLineCaption1; GLAccTaxonomyLineCaption1Lbl)
                {
                }
                column(TaxonomyLineCaption; TaxonomyLineCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        More := TempGLAcc2.Find('-')
                    else
                        More := TempGLAcc2.Next <> 0;
                    if not More then
                        CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    TempGLAcc2.SetRange(Blocked, true);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TempGLAcc1.Reset();
                TempGLAcc1.DeleteAll();
                TempGLAcc2.Reset();
                TempGLAcc2.DeleteAll();

                TempGLAcc.Reset();
                if TempGLAcc.Find('-') then
                    repeat
                        TempGLAcc1 := TempGLAcc;
                        TempGLAcc1.Insert();
                    until TempGLAcc.Next = 0;
            end;

            trigger OnPreDataItem()
            begin
                GLAcc.SetRange("Account Type", GLAcc."Account Type"::Posting);
                if GLAcc.Find('-') then
                    repeat
                        TempGLAcc := GLAcc;
                        TempGLAcc.Insert();
                    until GLAcc.Next = 0;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        GLAcc: Record "G/L Account";
        TempGLAcc: Record "G/L Account" temporary;
        TempGLAcc1: Record "G/L Account" temporary;
        TempGLAcc2: Record "G/L Account" temporary;
        NumGLMapLine: Integer;
        TotalNumGLMapLine: Integer;
        More: Boolean;
        WarningStr: Text[250];
        Text001: Label 'You have defined G/L Mapping for %1 %2.';
        Text002: Label 'You have defined a %1 for %2 %3.';
        WarningStr1: Text[250];
        PageNoCaptionLbl: Label 'Page';
        GLAccountCaptionLbl: Label 'XBRL Mapping of G/L Accounts';
        TaxonomyNameCaptionLbl: Label 'Taxonomy Name';
        LabelCaptionLbl: Label 'Label';
        WarningLbl: Label 'Warning:';
        GLMappingCaptionLbl: Label 'G/L Mapping';
        GLAccTaxonomyLineCaptionLbl: Label 'G/L Accounts that are not mapped to a taxonomy line.';
        IncomeBalCaptionLbl: Label 'Income/Balance';
        NameCaptionLbl: Label 'Name';
        NoCaptionLbl: Label 'No.';
        GLAccTaxonomyLineCaption1Lbl: Label 'G/L Accounts that are mapped to more than one taxonomy line.';
        TaxonomyLineCaptionLbl: Label 'Used in Taxonomy Lines No.';
}

