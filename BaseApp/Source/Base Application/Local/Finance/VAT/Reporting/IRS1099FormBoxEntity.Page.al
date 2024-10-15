// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Integration.Graph;
using System.Reflection;

page 10900 "IRS 1099 Form-Box Entity"
{
    Caption = 'irs1099Codes', Locked = true;
    DelayedInsert = true;
    EntityName = 'irs1099Code';
    EntitySetName = 'irs1099Codes';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "IRS 1099 Form-Box";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                }
                field("code"; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FieldNo(Code));
                    end;
                }
                field(displayName; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FieldNo(Description));
                    end;
                }
                field(minimumReportable; Rec."Minimum Reportable")
                {
                    ApplicationArea = All;
                    Caption = 'MinimumReportable', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(Rec.FieldNo("Minimum Reportable"));
                    end;
                }
                field(lastModifiedDateTime; Rec."Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        Rec.Insert(true);

        RecRef.GetTable(Rec);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, CurrentDateTime);
        RecRef.SetTable(Rec);

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.GetBySystemId(Rec.SystemId);

        if Rec.Code = IRS1099FormBox.Code then
            Rec.Modify(true)
        else begin
            IRS1099FormBox.TransferFields(Rec, false);
            IRS1099FormBox.Rename(Rec.Code);
            Rec.TransferFields(IRS1099FormBox);
        end;
    end;

    var
        TempFieldSet: Record "Field" temporary;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::"IRS 1099 Form-Box", FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::"IRS 1099 Form-Box";
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

