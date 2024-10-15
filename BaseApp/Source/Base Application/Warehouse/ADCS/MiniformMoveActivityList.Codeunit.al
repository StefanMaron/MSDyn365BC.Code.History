namespace Microsoft.Warehouse.ADCS;

using Microsoft.Warehouse.Activity;
using System;
using System.Xml;

codeunit 7710 "Miniform Move Activity List"
{
    TableNo = "Miniform Header";

    trigger OnRun()
    var
        MiniformMgmt: Codeunit "Miniform Management";
    begin
        MiniformMgmt.Initialize(
          MiniformHeader, Rec, DOMxmlin, ReturnedNode,
          RootNode, XMLDOMMgt, ADCSCommunication, ADCSUserId,
          CurrentCode, StackCode, WhseEmpId, LocationFilter);

        if Rec.Code <> CurrentCode then
            PrepareData()
        else
            ProcessSelection();

        Clear(DOMxmlin);
    end;

    var
        MiniformHeader: Record "Miniform Header";
        MiniformHeader2: Record "Miniform Header";
        XMLDOMMgt: Codeunit "XML DOM Management";
        ADCSCommunication: Codeunit "ADCS Communication";
        ADCSMgt: Codeunit "ADCS Management";
        RecRef: RecordRef;
        ReturnedNode: DotNet XmlNode;
        DOMxmlin: DotNet XmlDocument;
        RootNode: DotNet XmlNode;
#pragma warning disable AA0074
        Text000: Label 'Function not Found.';
        Text006: Label 'No input Node found.';
#pragma warning restore AA0074
        TextValue: Text[250];
        ADCSUserId: Text[250];
        WhseEmpId: Text[250];
        LocationFilter: Text[250];
        CurrentCode: Text[250];
        PreviousCode: Text[250];
        StackCode: Text[250];
        Remark: Text[250];
        ActiveInputField: Integer;
#pragma warning disable AA0074
        Text009: Label 'No Documents found.';
#pragma warning restore AA0074

    local procedure ProcessSelection()
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
        FuncGroup: Record "Miniform Function Group";
        RecId: RecordID;
        TableNo: Integer;
    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := ReturnedNode.InnerText
        else
            Error(Text006);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.Open(TableNo);
        Evaluate(RecId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if RecRef.Get(RecId) then begin
            RecRef.SetTable(WhseActivityHeader);
            WhseActivityHeader.SetCurrentKey(Type, "No.");
            WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type);
            WhseActivityHeader.SetRange("Assigned User ID", WhseEmpId);
            WhseActivityHeader.SetFilter("Location Code", LocationFilter);
            RecRef.GetTable(WhseActivityHeader);
            ADCSCommunication.SetRecRef(RecRef);
        end else begin
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            exit;
        end;

        FuncGroup.KeyDef := ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue);
        ActiveInputField := 1;

        case FuncGroup.KeyDef of
            FuncGroup.KeyDef::Esc:
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            FuncGroup.KeyDef::First:
                ADCSCommunication.FindRecRef(0, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::LnDn:
                if not ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List") then
                    Remark := Text009;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Last:
                ADCSCommunication.FindRecRef(3, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::PgDn:
                if not ADCSCommunication.FindRecRef(4, MiniformHeader."No. of Records in List") then
                    Remark := Text009;
            FuncGroup.KeyDef::PgUp:
                ADCSCommunication.FindRecRef(5, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Input:
                begin
                    ADCSCommunication.IncreaseStack(DOMxmlin, MiniformHeader.Code);
                    ADCSCommunication.GetNextMiniForm(MiniformHeader, MiniformHeader2);
                    MiniformHeader2.SaveXMLin(DOMxmlin);
                    CODEUNIT.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
                end;
            else
                Error(Text000);
        end;

        if not (FuncGroup.KeyDef in [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Input]) then
            SendForm(ActiveInputField);
    end;

    local procedure PrepareData()
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        WhseActivityHeader.Reset();
        WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type::Movement);
        if WhseEmpId <> '' then begin
            WhseActivityHeader.SetRange("Assigned User ID", WhseEmpId);
            WhseActivityHeader.SetFilter("Location Code", LocationFilter);
        end;
        if not WhseActivityHeader.FindFirst() then begin
            if ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RunReturn') = '0' then begin
                ADCSMgt.SendError(Text009);
                exit;
            end;
            ADCSCommunication.DecreaseStack(DOMxmlin, PreviousCode);
            MiniformHeader2.Get(PreviousCode);
            MiniformHeader2.SaveXMLin(DOMxmlin);
            CODEUNIT.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
        end else begin
            RecRef.GetTable(WhseActivityHeader);
            ADCSCommunication.SetRecRef(RecRef);
            ActiveInputField := 1;
            SendForm(ActiveInputField);
        end;
    end;

    local procedure SendForm(InputField: Integer)
    begin
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;
}

