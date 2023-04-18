codeunit 5483 "Graph Mgt - Employee"
{

    trigger OnRun()
    begin
    end;

    procedure ProcessComplexTypes(var Employee: Record Employee; PostalAddressJSON: Text)
    begin
        UpdatePostalAddress(PostalAddressJSON, Employee);
    end;

    procedure PostalAddressToJSON(Employee: Record Employee) JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with Employee do
            GraphMgtComplexTypes.GetPostalAddressJSON(Address, "Address 2", City, County, "Country/Region Code", "Post Code", JSON);
    end;

    local procedure UpdatePostalAddress(PostalAddressJSON: Text; var Employee: Record Employee)
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if PostalAddressJSON = '' then
            exit;

        with Employee do begin
            RecRef.GetTable(Employee);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(PostalAddressJSON, RecRef,
              FieldNo(Address), FieldNo("Address 2"), FieldNo(City), FieldNo(County), FieldNo("Country/Region Code"), FieldNo("Post Code"));
            RecRef.SetTable(Employee);
        end;
    end;
}
