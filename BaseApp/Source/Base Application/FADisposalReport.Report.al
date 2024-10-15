report 31047 "FA Disposal Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FADisposalReport.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'FA Disposal Report';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            column(Fixed_Asset_Inactive; Inactive)
            {
            }
            column(Employee_FullName; Employee.FullName)
            {
            }
            column(DeprBookCode; DeprBookCode)
            {
            }
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
            column(DisposalRepDate; DisposalRepDate)
            {
            }
            column(DisposalRepNo; DisposalRepNo)
            {
            }
            column(CompanyInfo__Registration_No__; CompanyInfo."Registration No.")
            {
            }
            column(CompanyInfo__Tax_Registration_No__; CompanyInfo."Tax Registration No.")
            {
            }
            column(Employee_FullNameCaption; Employee_FullNameCaptionLbl)
            {
            }
            column(Fixed_Asset_InactiveCaption; FieldCaption(Inactive))
            {
            }
            column(DeprBookCodeCaption; DeprBookCodeCaptionLbl)
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
            column(FALocation_NameCaption; FALocation_NameCaptionLbl)
            {
            }
            column(Fixed_Asset_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Fixed_Asset__No__Caption; Fixed_Asset__No__CaptionLbl)
            {
            }
            column(FA_Disposal_ReportCaption; FA_Disposal_ReportCaptionLbl)
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
            column(DisposalRepDateCaption; DisposalRepDateCaptionLbl)
            {
            }
            column(DisposalRepNoCaption; DisposalRepNoCaptionLbl)
            {
            }
            column(CompanyInfo__Registration_No__Caption; CompanyInfo__Registration_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Tax_Registration_No__Caption; CompanyInfo__Tax_Registration_No__CaptionLbl)
            {
            }
            dataitem("FA Depreciation Book"; "FA Depreciation Book")
            {
                DataItemLink = "FA No." = FIELD("No.");
                DataItemTableView = SORTING("FA No.", "Depreciation Book Code");
                column(FA_Depreciation_Book__Book_Value_on_Disposal_; "Book Value on Disposal")
                {
                }
                column(FA_Depreciation_Book__Gain_Loss_; "Gain/Loss")
                {
                }
                column(FA_Depreciation_Book__Proceeds_on_Disposal_; "Proceeds on Disposal")
                {
                }
                column(FA_Depreciation_Book__Book_Value_; "Book Value")
                {
                }
                column(FA_Depreciation_Book_Depreciation; Depreciation)
                {
                }
                column(FA_Depreciation_Book__Acquisition_Cost_; "Acquisition Cost")
                {
                }
                column(FA_Depreciation_Book__Acquisition_Date_; "Acquisition Date")
                {
                }
                column(FADisposalRepDate; FADisposalRepDate)
                {
                }
                column(V1__; '1.')
                {
                }
                column(Member_1_; Member[1])
                {
                }
                column(V2__; '2.')
                {
                }
                column(Member_2_; Member[2])
                {
                }
                column(EmptyString; '')
                {
                }
                column(EmptyString_Control1470057; '')
                {
                }
                column(V2___; '2. ')
                {
                }
                column(V1___; '1. ')
                {
                }
                column(FA_Depreciation_Book__Proceeds_on_Disposal_Caption; FieldCaption("Proceeds on Disposal"))
                {
                }
                column(FA_Depreciation_Book__Gain_Loss_Caption; FieldCaption("Gain/Loss"))
                {
                }
                column(FA_Depreciation_Book__Book_Value_on_Disposal_Caption; FieldCaption("Book Value on Disposal"))
                {
                }
                column(FA_Depreciation_Book__Book_Value_Caption; FieldCaption("Book Value"))
                {
                }
                column(FA_Depreciation_Book_DepreciationCaption; FieldCaption(Depreciation))
                {
                }
                column(FA_Depreciation_Book__Acquisition_Cost_Caption; FieldCaption("Acquisition Cost"))
                {
                }
                column(FA_Depreciation_Book__Acquisition_Date_Caption; FieldCaption("Acquisition Date"))
                {
                }
                column(FADisposalRepDateCaption; FADisposalRepDateCaptionLbl)
                {
                }
                column(Committee_members_Caption; Committee_members_CaptionLbl)
                {
                }
                column(Comments_Caption; Comments_CaptionLbl)
                {
                }
                column(Date__SignatureCaption; Date__SignatureCaptionLbl)
                {
                }
                column(Date__SignatureCaption_Control1470061; Date__SignatureCaption_Control1470061Lbl)
                {
                }
                column(Approved_by_committee_members_Caption; Approved_by_committee_members_CaptionLbl)
                {
                }
                column(FA_Depreciation_Book_FA_No_; "FA No.")
                {
                }
                column(FA_Depreciation_Book_Depreciation_Book_Code; "Depreciation Book Code")
                {
                }
                column(FA_Depreciation_Book_Appreciation; Appreciation)
                {
                }
                column(FA_Depreciation_Book_Appreciation_Caption; FieldCaption(Appreciation))
                {
                }
                column(FA_Depreciation_Book_BookValueAfterDisposalCaption; BookValueAfterDisposalLbl)
                {
                }
                column(FA_Depreciation_Book_BookValueAfterDisposal; BookValueAfterDisposal)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintFADispRepDate then
                        FADisposalRepDate := DisposalRepDate
                    else
                        FADisposalRepDate := "Disposal Date";
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Depreciation Book Code", DeprBookCode);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not Location.Get("Location Code") then
                    Location.Init();
                if not FALocation.Get("FA Location Code") then
                    FALocation.Init();
                if not Employee.Get("Responsible Employee") then
                    Employee.Init();
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
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
                    field(DisposalRepNo; DisposalRepNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'FA Disposal Report No.';
                        ToolTip = 'Specifies a fixed asset disposal report number.';
                    }
                    field(DisposalRepDate; DisposalRepDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'FA Disposal Report Date';
                        Enabled = FADisposalReportDateCtrlEnable;
                        ToolTip = 'Specifies a fixed asset disposal report date.';
                    }
                    field(PrintFADispRepDate; PrintFADispRepDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print FA Disp. Report Date';
                        ToolTip = 'Specifies to print the fixed asset disposal report date.';

                        trigger OnValidate()
                        begin
                            PrintFADispRepDateOnAfterValid;
                        end;
                    }
                    field("Member[1]"; Member[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '1. Persona';
                        ToolTip = 'Specifies an employee name from the Company Officials table. Each persona will print on the report with a corresponding signature line for authorization.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            CompanyOfficials.Reset();
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
                            CompanyOfficials.Reset();
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
            FADisposalReportDateCtrlEnable := true;
        end;

        trigger OnOpenPage()
        begin
            FADisposalReportDateCtrlEnable := PrintFADispRepDate;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if DisposalRepNo = '' then
            Error(EmptyRepNoErr);
        if PrintFADispRepDate then
            if DisposalRepDate = 0D then
                Error(EmptyRepDateErr);
        if DeprBookCode = '' then
            Error(EmptyDeprBookErr);
    end;

    var
        CompanyOfficials: Record "Company Officials";
        CompanyInfo: Record "Company Information";
        Location: Record Location;
        FALocation: Record "FA Location";
        Employee: Record Employee;
        FormatAddr: Codeunit "Format Address";
        DisposalRepNo: Code[20];
        DisposalRepDate: Date;
        DeprBookCode: Code[20];
        CompanyAddr: array[8] of Text[100];
        PrintFADispRepDate: Boolean;
        FADisposalRepDate: Date;
        Member: array[2] of Text[100];
        [InDataSet]
        FADisposalReportDateCtrlEnable: Boolean;
        EmptyRepNoErr: Label 'FA Disposal Report No. must not be empty.';
        EmptyRepDateErr: Label 'FA Disposal Report Date must not be empty.';
        EmptyDeprBookErr: Label 'Depreciation Book Code must not be empty.';
        Employee_FullNameCaptionLbl: Label 'Responsible Empl.';
        DeprBookCodeCaptionLbl: Label 'FA Depreciation Book';
        FALocation_NameCaptionLbl: Label 'FA Location';
        Fixed_Asset__No__CaptionLbl: Label 'Fixed Asset No.';
        FA_Disposal_ReportCaptionLbl: Label 'FixedAsset Disposal';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        DisposalRepDateCaptionLbl: Label 'Disposal Report Date';
        DisposalRepNoCaptionLbl: Label 'Disposal Report No.';
        CompanyInfo__Registration_No__CaptionLbl: Label 'Reg. No.';
        CompanyInfo__Tax_Registration_No__CaptionLbl: Label 'Tax Reg. No.';
        FADisposalRepDateCaptionLbl: Label 'Disposal Date';
        Committee_members_CaptionLbl: Label 'Committee members:';
        Comments_CaptionLbl: Label 'Comments:';
        Date__SignatureCaptionLbl: Label 'Date, Signature';
        Date__SignatureCaption_Control1470061Lbl: Label 'Date, Signature';
        Approved_by_committee_members_CaptionLbl: Label 'Approved by committee members:';
        BookValueAfterDisposalLbl: Label 'Book Value after Disp.';
        BookValueAfterDisposal: Decimal;

    local procedure PrintFADispRepDateOnAfterValid()
    begin
        if not PrintFADispRepDate then
            DisposalRepDate := 0D;
        FADisposalReportDateCtrlEnable := PrintFADispRepDate;
    end;
}

