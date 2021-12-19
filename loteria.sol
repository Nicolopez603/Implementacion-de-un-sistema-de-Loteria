// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;
import "./erc20.sol";

contract loteria{

    //Instanciamos el contracto erc20
    ERC20Basic private token;

    //Direcciones 
    address public owner;
    address public contrato;

    //Numero de tokens a crear
    uint public tokens_creados = 10000;

    //Evento de compra de tokens
    event comprandoTokens(uint, address);



    
    constructor () public {
    //Tenemos los tokens creados una vez que se desplegue el contrato
        tokens = new ERC20Basic(tokens_creados);
        
        owner = msg.sender;
        
        contrato = address(this);

    }

    //--------------------------- TOKEN --------------------

    //Establecemos el precio de los tokens en ethers
    function precioTokens(uint _numTokens) internal pure returns (uint){
       // 1 Token = 1 ether
        return _numTokens * (1 ether);
    }

    //Funcion que permite generar mas tokens por la loteria

    function generarTokens(uint _numTokens) public unicamenteEjecutable(msg.sender) returns(uint){
        token.increaseTotalSupply(_numTokens);
    
    }

    //Modifier solamente accesible unicamente por el owner del contrato
    modifier unicamenteEjecutable(address _direccion){
        require(_direccion = owner, "No tene permisos para ejecutar esta funcion");
    _;
    }


    //Comprar tokens para adquirir numeros en la loteria

    function compraTokens(uint _numTokens) public payable{
        //Calculamos el costo de los tokens
        uint coste = precioTokens(_numTokens);
        
        //Se requiere que el valor de ethers introducidos por el cliente sea equivalente al coste
        require(msg.value >= coste, "Compra menos tokens o paga con mas Ethers");

        //Necesito el cambio si pago con mas ethers
        uint returnValue = msg.value - coste;

        //Transferencia de la diferencia
        msg.sender.transfer(returnValue);

        //Obtenemos el balance de tokens del contrato
        uint balance = tokensDisponibles;

        //Filtro para evaluar los tokens a comprar con los tokens disponibles
        require(_numTokens <= balance, "Compra una cantidad de tokens adecuados");

        //Transferencia de tokens al comprador
        token.transfer(msg.sender, numTokens);

        //Emitimos el evento de compra de tokens
        emit comprandoTokens(_numTokens, msg.sender);
    }


    //Balance de tokens de loteria
    function tokensDisponibles() public view returns(uint) {
        return token.balanceOf(contrato);
    }

    //Balance de tokens que se van a acumular en el Bote
    function bote() public view returns(uint){
        return token.balanceOf(owner);
    }


    //Funcion que permite ver la cantidad de tokens a los usuarios
    function misTokens() public view returns (uint){
        return token.balanceOf(msg.sender);
    }
    

    //--------------------------- LOTERIA --------------------

    //precio del boleto en tokens
    uint public precioBoleto = 5;

    //Relacion entre la persona que compra los boletos y los numeros de los boletos
    //Uint [] porque puede comprar varios boletos
    mapping(address => uint[]) id_cliente;

    //Relacion necesaria para identificar al ganador
    mapping(uint => address) adn_boleto;

    //Numero aleatorio para generar boletos con numeros aleatorios
    uint randNonce = 0;

    //Boletos generados
    uint [] boletos_comprados;

    //Eventos
    //Cuando se compra un boleto 
    event boleto_comprado(uint, address);
    
    //Evento del ganador
    event boleto_ganador(uint);

    //evento para devolver tokens
    event tokens_devueltos(uint, address);

    //Funcion para comprar boletos de loteria
    function compraBoleto (uint _boletos) public {
        //Calculamos el precio total de los boletos a comprar
        uint precio_total = _boletos * precioBoleto;

        //Filtramos los tokens a pagar
        require(precio_total <= misTokens(), "Necesitas comprar mas tokens");

        //Transferencia de tokens al bote
        token.transferenciaLoteria(msg.sender, owner, precio_total);


        /*
        Generamos un for que toma la marca de tiempo actual, el msg sender, y un nonce
        (es un numero que solo se utiliza una vez para que no ejecutemos dos veces la misma funcion de hash con los mismos parametros) en incremento.
        Luego se utiliza keccak256 para convertir estas entradas a un hash aleatorio y seguido convertimos ese hash a un uint
        y utilizamos lo dividimos entre 10.000 para tomar los ultimos 4 digitos
        Dando un valor aleatorio entre 0 y 9999
        */
        for(uint i = 0; i< _boletos; i++){
            uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 10000;
            randNonce++;
            
            //Almacenamos los datos de los boletos
            id_cliente[msg.sender].push(random);
            
            //Numero de boleto comprado, que se asigna de forma aleatoria
            boletos_comprados.push(random);
            
            //Asignacion del ADN del boleto para tener un ganador
            adn_boleto[random] = msg.sender;

            //Emision del evento
            emit boleto_comprado(random, msg.sender);

        }
    }


    //funcion que nos permite visualizar el numero de boletos de una persona 
    function tusBoletos() public view returns (uint [] memory){
        return id_cliente[msg.sender];
    }

    //Funcion para generar un ganador e ingresarle los tokens
    function ganador() public unicamenteEjecutable(msg.sender){
        //Debe tener boletos comprados para generar un ganador
        require(boletos_comprados.length > 0 ,"No hay boletos comprados");

        //Declaracion de la longitud del array
        uint longitud = boletos_comprados.length;

        //de manera aleatoriamente elegimos un numero entre 0 y longitud
        //1- Eleccion de una posicion aleatoria del array
        uint posicion_array = uint(uint(keccak256(abi.encodePacked(block.timestamp))) % longitud);
    
        //2 - Hacemos la eleccion de los numeros aleatorios mediante la posicion del array aleatorio
        uint eleccion = boletos_comprados[posicion_array];

        //Emitimos el evento del ganador del bote
        emit boleto_ganador(eleccion);

        //Identificamos el address del ganador 
        address direccion_ganador  = adn_boleto[eleccion];

        //Enviamos los token del premio al ganador
        token.transferenciaLoteria(msg.sender, direccion_ganador, bote());
    }

    //Funcion que devuelve los tokens
    function devolverTokens(uint _numTokens) public payable {
        //El numero de tokens a devolver debe ser mayor a 0
        require(_numTokens = >0 , "Necesitas devolver un numero positivo de tokens")
    
        //El usuario debe tener los tokens que desea devolver
        require(_numTokens <= misTokens(), "No tienes los tokens que deseas devolver");

        //-----Devolucion---------
        //1 - El cliente devuelva los tokens
        //2 - La loteria paga los tokens devueltos
        token.transferenciaLoteria(msg.sender, address(this), _numTokens);
        msg.sender.transfer(precioTokens(_numTokens));

        //emitimos un evento mostrando que devolvimos tokens y el address del que ejecuta la funcion
        emit tokens_devueltos(_numTokens, msg.sender);

    }

}
