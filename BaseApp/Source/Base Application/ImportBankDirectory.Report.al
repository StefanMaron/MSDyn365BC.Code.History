report 11504 "Import Bank Directory"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ImportBankDirectory.rdlc';
    Caption = 'Import Bank Directory';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(ReadRec; ReadRec)
            {
            }
            column(BankDirectoryTableCaption; BankDirectory.TableCaption)
            {
            }
            column(WriteRec; WriteRec)
            {
            }
            column(ImportText; ImportText)
            {
            }
            column(FileName; FileName)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ImportBankDirectoryCaption; ImportBankDirectoryCaptionLbl)
            {
            }
            dataitem("Customer Bank Account"; "Customer Bank Account")
            {
                DataItemTableView = SORTING("Customer No.", Code) ORDER(Ascending) WHERE("Bank Branch No." = FILTER(<> ''));
                column(CustomerBankAccountTableCaption; "Customer Bank Account".TableCaption)
                {
                }
                column(CustomerNo_CustomerBankAccount; "Customer No.")
                {
                }
                column(Code_CustomerBankAccount; Code)
                {
                }
                column(OldBranchNo; OldBranchNo)
                {
                }
                column(BankBranchNo_CustomerBankAccount; "Bank Branch No.")
                {
                }
                column(BranchNotFound; BranchNotFound)
                {
                }
                column(OldBankBranchNoCaption; OldBankBranchNoCaptionLbl)
                {
                }
                column(CodeCaption_CustomerBankAccount; FieldCaption(Code))
                {
                }
                column(CustomerNoCaption_CustomerBankAccount; FieldCaption("Customer No."))
                {
                }
                column(NewBankBranchNoCaption; NewBankBranchNoCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    OldBranchNo := '';
                    BranchNotFound := '';

                    if not BankDirectory.Get("Bank Branch No.") then
                        BranchNotFound := StrSubstNo(Text005, "Bank Branch No.", BankDirectory.TableCaption)
                    else
                        if BankDirectory."New Clearing No." <> '' then begin
                            OldBranchNo := "Bank Branch No.";
                            Validate("Bank Branch No.", BankDirectory."New Clearing No.");
                            if AutoUpdate then
                                Modify;
                        end else
                            CurrReport.Skip;
                end;

                trigger OnPreDataItem()
                begin
                    BankDirectory.Reset;
                end;
            }
            dataitem("Vendor Bank Account"; "Vendor Bank Account")
            {
                DataItemTableView = SORTING("Vendor No.", Code) ORDER(Ascending) WHERE("Clearing No." = FILTER(<> ''));
                column(VendorBankAccountTableCaption; "Vendor Bank Account".TableCaption)
                {
                }
                column(VendorNo_VendorBankAccount; "Vendor No.")
                {
                }
                column(Code_VendorBankAccount; "Vendor Bank Account".Code)
                {
                }
                column(ClearingNo_VendorBankAccount; "Vendor Bank Account"."Clearing No.")
                {
                }
                column(ClearingNo_VendorBankAccount2; VendorBankAccount2."Clearing No.")
                {
                }
                column(BranchNotFound_VendorBankAccount; BranchNotFound)
                {
                }
                column(VendorBankAccount2Code; VendorBankAccount2.Code)
                {
                }
                column(VendorNoCaption_VendorBankAccount; FieldCaption("Vendor No."))
                {
                }
                column(OldCodeCaption; OldCodeCaptionLbl)
                {
                }
                column(OldClearingNoCaption; OldClearingNoCaptionLbl)
                {
                }
                column(NewClearingNoCaption; NewClearingNoCaptionLbl)
                {
                }
                column(NewCodeCaption; NewCodeCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    OldBranchNo := '';
                    BranchNotFound := '';

                    if not BankDirectory.Get("Clearing No.") then
                        BranchNotFound := StrSubstNo(Text005, "Clearing No.", BankDirectory.TableCaption)
                    else
                        if BankDirectory."New Clearing No." <> '' then begin
                            VendorBankAccount2.SetRange("Vendor No.", "Vendor No.");
                            VendorBankAccount2.SetRange("Clearing No.", BankDirectory."New Clearing No.");
                            if not VendorBankAccount2.Find('-') then begin
                                VendorBankAccount2.Reset;
                                VendorBankAccount2.Init;
                                VendorBankAccount2.TransferFields("Vendor Bank Account");
                                VendorBankAccount2.Code := Format(Code + BankDirectory."New Clearing No.", -10);
                                VendorBankAccount2.Validate("Clearing No.", BankDirectory."New Clearing No.");
                                if AutoUpdate then
                                    if not VendorBankAccount2.Insert then
                                        BranchNotFound := StrSubstNo(Text007, "Vendor No.", Code);
                            end else
                                CurrReport.Skip;
                        end else
                            CurrReport.Skip;
                end;
            }
            dataitem(Other; "Integer")
            {
                DataItemTableView = SORTING(Number) ORDER(Ascending) WHERE(Number = CONST(1));
                PrintOnlyIfDetail = true;
                column(OtherText; OtherText)
                {
                }
                column(OtherCaption; OtherCaptionLbl)
                {
                }
                column(TableCaptionOther; TableCaptionLbl)
                {
                }
                column(FieldCaption; FieldCaptionLbl)
                {
                }
                column(BankDirectoryNewClearingNoCaption; NewClearingNoCaptionLbl)
                {
                }
                column(EntryCaption; EntryCaptionLbl)
                {
                }
                dataitem("DTA Setup"; "DTA Setup")
                {
                    DataItemTableView = SORTING("Bank Code") ORDER(Ascending) WHERE("DTA Sender Clearing" = FILTER(<> ''));
                    column(TableCaption_DTASetup; TableCaption)
                    {
                    }
                    column(DTASenderClearing_DTASetup; FieldCaption("DTA Sender Clearing"))
                    {
                    }
                    column(BankDirectoryNewClearingNo; BankDirectory."New Clearing No.")
                    {
                    }
                    column(DTASetupBranchNotFound; BranchNotFound)
                    {
                    }
                    column(DTASetupBankCode; "Bank Code")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        OldBranchNo := '';
                        BranchNotFound := '';

                        if not BankDirectory.Get("DTA Sender Clearing") then
                            BranchNotFound := StrSubstNo(Text005, "DTA Sender Clearing", BankDirectory.TableCaption)
                        else
                            if BankDirectory."New Clearing No." = '' then
                                CurrReport.Skip;
                    end;
                }
                dataitem("LSV Setup"; "LSV Setup")
                {
                    DataItemTableView = SORTING("Bank Code") ORDER(Ascending) WHERE("LSV Sender Clearing" = FILTER(<> ''));
                    column(LSVSetupTableCaption; TableCaption)
                    {
                    }
                    column(LSVSenderClearingCaption; FieldCaption("LSV Sender Clearing"))
                    {
                    }
                    column(BankDirectoryNewClearingNo_LSVSetup; BankDirectory."New Clearing No.")
                    {
                    }
                    column(BranchNotFoundLSVSetup; BranchNotFound)
                    {
                    }
                    column(BankCode_LSVSetup; "Bank Code")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        OldBranchNo := '';
                        BranchNotFound := '';

                        if not BankDirectory.Get("LSV Sender Clearing") then
                            BranchNotFound := StrSubstNo(Text005, "LSV Sender Clearing", BankDirectory.TableCaption)
                        else
                            if BankDirectory."New Clearing No." = '' then
                                CurrReport.Skip;
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if AutoUpdate then
                        OtherText := Text006;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ReadRec := StrSubstNo(Text001, NoOfRecsRead);
                WriteRec := StrSubstNo(Text002, NoOfRecsWritten);

                if AutoUpdate then
                    ImportText := Text004
                else
                    ImportText := Text003;
            end;

            trigger OnPreDataItem()
            begin
                if ServerFileName <> '' then
                    BankDirectory.ImportBankDirectoryDirect(ServerFileName, NoOfRecsRead, NoOfRecsWritten);
            end;
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
                    field(FileName; FileName)
                    {
                        Caption = 'File Name';
                        ToolTip = 'Specifies the name of the file to be imported.';

                        trigger OnAssistEdit()
                        begin
                            FileName := FileMgt.OpenFileDialog(Text009, '', Text008);
                            if not FileMgt.IsLocalFileSystemAccessible then begin
                                ServerFileName := FileName;
                                FileName := CopyStr(FileMgt.GetFileName(ServerFileName), 1, MaxStrLen(FileName));
                            end;
                        end;
                    }
                    field(AutoUpdate; AutoUpdate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Automatically update Clearing Numbers';
                        MultiLine = true;
                        ToolTip = 'Specifies that the bank clearing numbers are automatically updated as they are imported.';
                    }
                    label(Control1150000)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Text19057439;
                        ShowCaption = false;
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

    trigger OnPostReport()
    begin
        if Exists(ServerFileName) then
            Erase(ServerFileName);
    end;

    trigger OnPreReport()
    begin
        if FileMgt.IsLocalFileSystemAccessible then
            ServerFileName := CopyStr(FileMgt.UploadFileToServer(FileName), 1, 1024);

        if ServerFileName = '' then
            CurrReport.Quit;
    end;

    var
        BankDirectory: Record "Bank Directory";
        VendorBankAccount2: Record "Vendor Bank Account";
        FileMgt: Codeunit "File Management";
        NoOfRecsRead: Integer;
        NoOfRecsWritten: Integer;
        AutoUpdate: Boolean;
        FileName: Text[1024];
        ServerFileName: Text[1024];
        ReadRec: Text[80];
        WriteRec: Text[80];
        ImportText: Text[80];
        BranchNotFound: Text[80];
        OldBranchNo: Code[20];
        OldBranchNo2: Code[20];
        OldCode: Code[20];
        NewBranchNo: Code[20];
        TableName: Text[30];
        FieldName: Text[50];
        OtherText: Text[100];
        Text001: Label '%1 Records have been imported.';
        Text002: Label '%1 Records have been created.';
        Text003: Label 'The system has found the following aged clearing numbers:';
        Text004: Label 'The system successfully updated the following clearing numbers:';
        Text005: Label 'Clearingnumber %1 not found in %2.';
        Text006: Label 'The system has not automatically adjusted the following data. This has to be done manually.';
        Text007: Label 'The Entry %1 %2 cannot be updated.';
        Text008: Label 'All Files (*.*)|*.*';
        Text009: Label 'Open Bank Directory file';
        Text010: Label 'The latest Bank Directory file can be downloaded from www.sic.ch.';
        Text19057439: Label 'The latest Bank Directory file can be downloaded from www.sic.ch.';
        PageCaptionLbl: Label 'Page';
        ImportBankDirectoryCaptionLbl: Label 'Import Bank Directory';
        OldBankBranchNoCaptionLbl: Label 'Old Bank Branch No.';
        NewBankBranchNoCaptionLbl: Label 'New Bank Branch No.';
        OldCodeCaptionLbl: Label 'Old Code';
        OldClearingNoCaptionLbl: Label 'Old Clearing No.';
        NewClearingNoCaptionLbl: Label 'New Clearing No.';
        NewCodeCaptionLbl: Label 'New Code';
        OldBranchNo2CaptionLbl: Label 'Old Clearing No. 2';
        NewClearingNo2CaptionLbl: Label 'New Clearing No. 2';
        OtherCaptionLbl: Label 'Other';
        TableCaptionLbl: Label 'Table';
        FieldCaptionLbl: Label 'Field';
        EntryCaptionLbl: Label 'Entry';
}

