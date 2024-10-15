// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

#if not CLEAN23
using Microsoft.Purchases.Vendor;
#endif

page 532 "Company Sizes"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Company Size";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ToolTip = 'Specifies the code that identifies the company size.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the company size.';
                }
            }
        }
    }
#if not CLEAN23
    actions
    {
        area(Creation)
        {
            action(ImportOld)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Company Sizes file.';
                Enabled = false;
                Visible = false;
                Image = Import;
                ToolTip = 'Import Company Size Codes from the standard CSV file.';
                ObsoleteReason = 'Moved to the SE Core app';
                ObsoleteState = Pending;
                ObsoleteTag = '23.0';

                trigger OnAction()
                begin
                    RunImport();
                end;
            }
        }
        area(Promoted)
        {
            actionref(ImportOld_promoted; ImportOld)
            {
                ObsoleteReason = 'Moved to the SE Core app';
                ObsoleteState = Pending;
                ObsoleteTag = '23.0';
            }
        }
    }

    var
        ImportDoneMsg: Label 'Importing Company Sizes done. %1 matches found out of %2 total lines processed.', Comment = '%1,%2 - number of lines.';

    local procedure RunImport()
    var
        InStream: InStream;
        Line: Text;
        FileName: Text;
        TotalLines: Integer;
        MatchesFound: Integer;
    begin
        if not UploadIntoStream('', '', 'CSV Files|*.csv', FileName, InStream) then
            exit;

        repeat
            if InStream.ReadText(Line) > 0 then begin
                if ImportLine(Line) then
                    MatchesFound += 1;
                TotalLines += 1;
            end;
        until InStream.EOS();
        Message(ImportDoneMsg, MatchesFound, TotalLines);
    end;

    local procedure ImportLine(InputLine: Text) MatchFound: Boolean;
    var
        Vendor: Record Vendor;
        CompanySize: Record "Company Size";
        OutputList: List of [Text];
        CompanyVATREgNo: Code[20];
        CompanySizeCode: Code[20];
        CompanySizeDescription: Text[100];
    begin
        SplitLineToList(InputLine, OutputList);
        CompanyVATREgNo := CopyStr(OutputList.Get(1), 1, MaxStrLen(Vendor."VAT Registration No."));
        CompanySizeCode := CopyStr(OutputList.Get(3), 1, MaxStrLen(Vendor."Company Size Code"));
        CompanySizeDescription := CopyStr(OutputList.Get(4), 1, MaxStrLen(CompanySize.Description));
        if FindMatchingVendor(Vendor, CompanyVATREgNo) then begin
            if not CompanySize.Get(CompanySizeCode) then begin
                CompanySize.Code := CompanySizeCode;
                CompanySize.Description := CompanySizeDescription;
                CompanySize.Insert();
            end;
            Vendor."Company Size Code" := CompanySizeCode;
            Vendor.Modify();
            MatchFound := true;
        end;
    end;

    local procedure SplitLineToList(InputLine: Text; var List: List of [Text])
    var
        TabChar: Char;
        TabIndex: Integer;
    begin
        TabChar := 9;
        while StrPos(InputLine, TabChar) > 0 do begin
            TabIndex := StrPos(InputLine, TabChar);
            List.Add(CopyStr(InputLine, 1, TabIndex - 1));
            InputLine := CopyStr(InputLine, TabIndex + 1, StrLen(InputLine));
        end;
        List.Add(InputLine);
    end;

    local procedure FindMatchingVendor(var Vendor: Record Vendor; CompanyVATREgNo: Code[20]): Boolean
    begin
        Vendor.SetRange("VAT Registration No.", CompanyVATREgNo);
        if Vendor.FindFirst() then
            exit(true);
        Vendor.SetRange("VAT Registration No.", CopyStr('SE' + CompanyVATREgNo, 1, MaxStrLen(Vendor."VAT Registration No.")));
        if Vendor.FindFirst() then
            exit(true);
    end;
#endif
}
