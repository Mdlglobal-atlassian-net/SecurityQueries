import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.DefUse
import lib.dataflow_extra.CollectionsEdges
import semmle.code.java.dataflow.TaintTracking

/** General dataflow edges that are useful for hunting vulnerabilities but not included in the standard library.*/

/** Holds if `node1` is a tainted value assigned to a field and `node2` is an access to the field. This essentially
 *  says that if a field is assigned to a tainted value at some point, then any access to that field is considered tainted.
 *  This has high risk of producing FP, but worth a try to see what you get.
 */
predicate isTaintedFieldStep(DataFlow::Node node1, DataFlow::Node node2) {
  exists(Field f, RefType t | node1.asExpr() = f.getAnAssignedValue() and node2.asExpr() = f.getAnAccess() and
      node1.asExpr().getEnclosingCallable().getDeclaringType() = t and
      node2.asExpr().getEnclosingCallable().getDeclaringType() = t
  )  
}

/** Tracks an object once any of its field is assigned to something tainted. Can be risky in terms of FP.*/
predicate taintFieldFromQualifier(DataFlow::Node n1, DataFlow::Node n2) {
  exists(Field f |
    n1 = DataFlow::getFieldQualifier(n2.asExpr()) and
    n2.asExpr() = f.getAnAccess()
  )
}

/** Tracks from an object to the output of its `toString` method. */
predicate toStringStep(DataFlow::Node node1, DataFlow::Node node2) {
  exists(MethodAccess ma | ma.getMethod().getName() = "toString" and
      ma = node2.asExpr() and ma.getQualifier() = node1.asExpr()
  )
}

/** Bundle up the less risky edges that are usually ok for bug hunting.*/
predicate standardExtraEdges(DataFlow::Node node1, DataFlow::Node node2) {
  collectionsGetEdge(node1, node2) or
  forLoopEdge(node1, node2) or
  toStringStep(node1, node2) or
  TaintTracking::localAdditionalTaintStep(node1, node2)
}