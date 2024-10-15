tableextension 18838 "Sales Header" extends "Sales Header"
{
    fields
    {
        field(18838; "Assessee Code"; code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            editable = false;
            trigger Onvalidate()
            var
                SalesLine: Record "Sales Line";
            begin
                salesline.reset();
                SalesLine.SetRange("Document Type", "Document Type");
                SalesLine.SetRange("Document No.", "No.");
                if not salesline.IsEmpty() then
                    SalesLine.ModifyAll("Assessee Code", "Assessee Code");
            end;
        }
    }
}
