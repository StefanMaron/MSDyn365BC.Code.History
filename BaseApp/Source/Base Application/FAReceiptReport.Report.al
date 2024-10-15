report 31046 "FA Receipt Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FAReceiptReport.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'FA Receipt Report';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            column(Fixed_Asset__Serial_No__; "Serial No.")
            {
            }
            column(Fixed_Asset__FA_Class_Code_; "FA Class Code")
            {
            }
            column(Fixed_Asset__FA_Subclass_Code_; "FA Subclass Code")
            {
            }
            column(FALocation_Name; FALocation.Name)
            {
            }
            column(Employee_FullName; Employee.FullName)
            {
            }
            column(Fixed_Asset_Inactive; Format(Inactive))
            {
            }
            column(DeprBookCode; DeprBookCode)
            {
            }
            column(UseStartDate; UseStartDate)
            {
            }
            column(Fixed_Asset__Description_2_; "Description 2")
            {
            }
            column(Fixed_Asset_Description; Description)
            {
            }
            column(Fixed_Asset__No__; "No.")
            {
            }
            column(CompanyAddr_6_; CompanyAddr[6])
            {
            }
            column(CompanyAddr_5_; CompanyAddr[5])
            {
            }
            column(CompanyAddr_4_; CompanyAddr[4])
            {
            }
            column(CompanyAddr_3_; CompanyAddr[3])
            {
            }
            column(CompanyAddr_2_; CompanyAddr[2])
            {
            }
            column(CompanyAddr_1_; CompanyAddr[1])
            {
            }
            column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
            {
            }
            column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
            {
            }
            column(CompanyInfo__Registration_No__; CompanyInfo."Registration No.")
            {
            }
            column(ReceiptNo; ReceiptNo)
            {
            }
            column(ReceiptDate; ReceiptDate)
            {
            }
            column(CompanyInfo__Tax_Registration_No__; CompanyInfo."Tax Registration No.")
            {
            }
            column(Fixed_Asset__Serial_No__Caption; FieldCaption("Serial No."))
            {
            }
            column(Fixed_Asset__FA_Class_Code_Caption; FieldCaption("FA Class Code"))
            {
            }
            column(Fixed_Asset__FA_Subclass_Code_Caption; FieldCaption("FA Subclass Code"))
            {
            }
            column(Employee_FullNameCaption; Employee_FullNameCaptionLbl)
            {
            }
            column(DeprBookCodeCaption; DeprBookCodeCaptionLbl)
            {
            }
            column(UseStartDateCaption; UseStartDateCaptionLbl)
            {
            }
            column(FALocation_NameCaption; FALocation_NameCaptionLbl)
            {
            }
            column(Fixed_Asset_InactiveCaption; FieldCaption(Inactive))
            {
            }
            column(Fixed_Asset_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Fixed_Asset__No__Caption; Fixed_Asset__No__CaptionLbl)
            {
            }
            column(FA_Receipt_ReportCaption; FA_Rcpt_ReportCaptionLbl)
            {
            }
            column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Registration_No__Caption; CompanyInfo__Registration_No__CaptionLbl)
            {
            }
            column(ReceiptNoCaption; RcptNoCaptionLbl)
            {
            }
            column(ReceiptDateCaption; RcptDateCaptionLbl)
            {
            }
            column(CompanyInfo__Tax_Registration_No__Caption; CompanyInfo__Tax_Registration_No__CaptionLbl)
            {
            }
            dataitem("FA Depreciation Book"; "FA Depreciation Book")
            {
                DataItemLink = "FA No." = FIELD("No.");
                DataItemTableView = SORTING("FA No.", "Depreciation Book Code");
                column(AcquisitionCost; AcquisitionCost)
                {
                }
                column(AcquisitionDate; AcquisitionDate)
                {
                }
                column(DisposedText; DisposedText)
                {
                }
                column(V2__; '2.')
                {
                }
                column(V1__; '1.')
                {
                }
                column(Member_1_; Member[1])
                {
                }
                column(Member_2_; Member[2])
                {
                }
                column(EmptyString; '')
                {
                }
                column(EmptyString_Control1470047; '')
                {
                }
                column(Employee_FullName_Control1470049; Employee.FullName)
                {
                }
                column(V2___Control1470053; '2.')
                {
                }
                column(V1___Control1470054; '1.')
                {
                }
                column(AcquisitionCostCaption; AcquisitionCostCaptionLbl)
                {
                }
                column(AcquisitionDateCaption; AcquisitionDateCaptionLbl)
                {
                }
                column(Committee_members_Caption; Committee_members_CaptionLbl)
                {
                }
                column(Comments_Caption; Comments_CaptionLbl)
                {
                }
                column(Accepted_by_Caption; Accepted_by_CaptionLbl)
                {
                }
                column(Approved_by_committee_members_Caption; Approved_by_committee_members_CaptionLbl)
                {
                }
                column(Date__SignatureCaption; Date__SignatureCaptionLbl)
                {
                }
                column(Date__SignatureCaption_Control1470056; Date__SignatureCaption_Control1470056Lbl)
                {
                }
                column(FA_Depreciation_Book_FA_No_; "FA No.")
                {
                }
                column(FA_Depreciation_Book_Depreciation_Book_Code; "Depreciation Book Code")
                {
                }
                column(FA_Depreciation_Book_DeprStartDate; DeprStartDate)
                {
                }
                column(FA_Depreciation_Book_DeprStartDateCaption; DeprStartDateCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Disposed := "Disposal Date" > 0D;
                    if Disposed then
                        DisposedText := DeprFaTxt
                    else
                        DisposedText := '';

                    CalcFields("Acquisition Cost", "Custom 2");
                    if "Acquisition Cost" <> 0 then
                        AcquisitionCost := "Acquisition Cost"
                    else
                        AcquisitionCost := "Custom 2";

                    AcquisitionDate := "Last Acquisition Cost Date";
                    DeprStartDate := "Depreciation Starting Date";
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Depreciation Book Code", DeprBookCode);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not Location.Get("Location Code") then
                    Location.Init;
                if not FALocation.Get("FA Location Code") then
                    FALocation.Init;
                if not Employee.Get("Responsible Employee") then
                    Employee.Init;

                if PrintFALedgDate then begin
                    FASetup.Get;
                    if FASetup."FA Acquisition As Custom 2" then begin
                        FALedgEntry.Reset;
                        FALedgEntry.SetCurrentKey(
                          "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date");
                        FALedgEntry.SetRange("FA No.", "No.");
                        FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
                        FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
                        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Custom 2");
                        if FALedgEntry.FindLast then begin
                            ReceiptDate := FALedgEntry."FA Posting Date";
                            ReceiptNo := FALedgEntry."Document No.";
                        end else begin
                            FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Acquisition Cost");
                            if FALedgEntry.FindLast then begin
                                ReceiptDate := FALedgEntry."FA Posting Date";
                                ReceiptNo := FALedgEntry."Document No.";
                            end;
                        end;
                    end else begin
                        FALedgEntry.Reset;
                        FALedgEntry.SetCurrentKey(
                          "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date");
                        FALedgEntry.SetRange("FA No.", "No.");
                        FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
                        FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
                        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Acquisition Cost");
                        if FALedgEntry.FindLast then begin
                            ReceiptDate := FALedgEntry."FA Posting Date";
                            ReceiptNo := FALedgEntry."Document No.";
                        end;
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get;
                FormatAddr.Company(CompanyAddr, CompanyInfo);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DeprBookCode; DeprBookCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Depreciation Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the depreciation book for the printing of entries.';
                    }
                    field(ReceiptNo; ReceiptNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'FA Receipt No.';
                        Enabled = FARcptNoCtrlEnable;
                        ToolTip = 'Specifies a fixed asset receipt number.';
                    }
                    field(ReceiptDate; ReceiptDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'FA Receipt Date';
                        Enabled = FARcptDateCtrlEnable;
                        ToolTip = 'Specifies a fixed asset receipt date.';
                    }
                    field(UseStartDate; UseStartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'FA Use Start Date';
                        Enabled = FAUseStartDateCtrlEnable;
                        ToolTip = 'Specifies a fixed asset start date.';
                    }
                    field(PrintFALedgDate; PrintFALedgDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print FA Ledger Entry Dates';
                        ToolTip = 'Specifies to print the fixed asset ledger entry dates.';

                        trigger OnValidate()
                        begin
                            PrintFALedgDateOnAfterValida;
                        end;
                    }
                    field("Member[1]"; Member[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '1. Persona';
                        ToolTip = 'Specifies an employee name from the Company Officials table. Each persona will print on the report with a corresponding signature line for authorization.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            CompanyOfficials.Reset;
                            if PAGE.RunModal(PAGE::"Company Officials", CompanyOfficials) = ACTION::LookupOK then
                                Member[1] := CompanyOfficials.FullName;
                        end;
                    }
                    field("Member[2]"; Member[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '2. Persona';
                        ToolTip = 'Specifies an employee name from the Company Officials table. Each persona will print on the report with a corresponding signature line for authorization.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            CompanyOfficials.Reset;
                            if PAGE.RunModal(PAGE::"Company Officials", CompanyOfficials) = ACTION::LookupOK then
                                Member[2] := CompanyOfficials.FullName;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            FAUseStartDateCtrlEnable := true;
            FARcptDateCtrlEnable := true;
            FARcptNoCtrlEnable := true;
        end;

        trigger OnOpenPage()
        begin
            FARcptNoCtrlEnable := not PrintFALedgDate;
            FARcptDateCtrlEnable := not PrintFALedgDate;
            FAUseStartDateCtrlEnable := not PrintFALedgDate;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if not PrintFALedgDate then begin
            if ReceiptNo = '' then
                Error(EmptyNoErr);
            if ReceiptDate = 0D then
                Error(EmptyDate1Err);
            if UseStartDate = 0D then
                Error(EmptyDate2Err);
        end;
        if DeprBookCode = '' then
            Error(EmptyDeprBookErr);
    end;

    var
        CompanyOfficials: Record "Company Officials";
        CompanyInfo: Record "Company Information";
        Location: Record Location;
        FALocation: Record "FA Location";
        Employee: Record Employee;
        FALedgEntry: Record "FA Ledger Entry";
        FASetup: Record "FA Setup";
        FormatAddr: Codeunit "Format Address";
        ReceiptNo: Code[35];
        ReceiptDate: Date;
        UseStartDate: Date;
        DeprBookCode: Code[20];
        Disposed: Boolean;
        DisposedText: Text[30];
        CompanyAddr: array[8] of Text[100];
        PrintFALedgDate: Boolean;
        DeprStartDate: Date;
        Member: array[2] of Text[100];
        AcquisitionDate: Date;
        AcquisitionCost: Decimal;
        [InDataSet]
        FARcptNoCtrlEnable: Boolean;
        [InDataSet]
        FARcptDateCtrlEnable: Boolean;
        [InDataSet]
        FAUseStartDateCtrlEnable: Boolean;
        DeprFaTxt: Label 'FA Disposed';
        EmptyNoErr: Label 'Receipt No. must not be empty.';
        EmptyDate1Err: Label 'Receipt date must not be empty.';
        EmptyDate2Err: Label 'FA Use Start Date must not be empty.';
        EmptyDeprBookErr: Label 'Depreciation Book Code must not be empty.';
        Employee_FullNameCaptionLbl: Label 'Responsible Empl.';
        DeprBookCodeCaptionLbl: Label 'FA Depreciation Book';
        UseStartDateCaptionLbl: Label 'FA Use Start Date';
        FALocation_NameCaptionLbl: Label 'FA Location';
        DeprStartDateCaptionLbl: Label 'FA Depr. Start Date';
        Fixed_Asset__No__CaptionLbl: Label 'Fixed Asset No.';
        FA_Rcpt_ReportCaptionLbl: Label 'Fixed Asset Receipt';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Registration_No__CaptionLbl: Label 'Reg. No.';
        RcptNoCaptionLbl: Label 'Receipt No.';
        RcptDateCaptionLbl: Label 'Receipt Date';
        CompanyInfo__Tax_Registration_No__CaptionLbl: Label 'Tax Reg. No.';
        AcquisitionCostCaptionLbl: Label 'Acquisition Cost';
        AcquisitionDateCaptionLbl: Label 'Acquisition Date';
        Committee_members_CaptionLbl: Label 'Committee members:';
        Comments_CaptionLbl: Label 'Comments:';
        Accepted_by_CaptionLbl: Label 'Accepted by:';
        Approved_by_committee_members_CaptionLbl: Label 'Approved by committee members:';
        Date__SignatureCaptionLbl: Label 'Date, Signature';
        Date__SignatureCaption_Control1470056Lbl: Label 'Date, Signature';

    local procedure PrintFALedgDateOnAfterValida()
    begin
        if PrintFALedgDate then begin
            ReceiptNo := '';
            ReceiptDate := 0D;
            UseStartDate := 0D;
        end;
        FARcptNoCtrlEnable := not PrintFALedgDate;
        FARcptDateCtrlEnable := not PrintFALedgDate;
        FAUseStartDateCtrlEnable := not PrintFALedgDate;
    end;
}

