const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp();

exports.nuevoMovimiento = onDocumentCreated(
    "parejas/{parejaId}/movimientos/{movimientoId}",
    async (event) => {
      const movimiento = event.data && event.data.data ?
  event.data.data() :
  null;

      if (!movimiento) {
        return;
      }

      console.log("Nuevo movimiento detectado:", movimiento);

      const parejaId = event.params.parejaId;

      const db = getFirestore();

      const parejaSnap = await db
          .collection("parejas")
          .doc(parejaId)
          .get();

      if (!parejaSnap.exists) {
        console.log("No se encontró la pareja.");
        return;
      }

      const pareja = parejaSnap.data();

      console.log("Pareja encontrada:", pareja);

      return null;
    },
);
