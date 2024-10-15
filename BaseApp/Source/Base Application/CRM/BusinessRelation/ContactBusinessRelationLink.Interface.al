namespace Microsoft.CRM.BusinessRelation;

interface "Contact Business Relation Link"
{
    /// <summary>
    /// Returns table and system id of record that match the No. field 
    /// </summary>
    /// <param name="No">The field to lookup</param>
    /// <param name="TableId">Table id of implementation</param>
    /// <param name="SystemId">System id for the found record</param>
    /// <returns>True if the record was found</returns>
    procedure GetTableAndSystemId(No: Code[20]; var TableId: Integer; var SystemId: Guid): Boolean
}